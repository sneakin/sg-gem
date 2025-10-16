require 'thread'
require_relative '../defer'
require_relative 'value'
require_relative 'missing'

module SG::Defer
  class Forked < Value
    class InChildError < RuntimeError
    end

    attr_reader :cmd, :io, :child_args, :pid
    
    def initialize cmd, child_args: nil, &child
      @cmd = cmd
      @child_args = child_args
      @child = child
      @io = IO.popen(@cmd, 'rb+')
      if @io
        @pid = @io.pid
        super() { run_monitor }
      else
        raise ArgumentError.new('No block given.') unless child
        super()
        @child.call(self, *@child_args)
      end
    end

    def run_monitor
      data = nil
      if @child && @cmd != '-'
        data = @child.call(@io, *@child_args)
        @io.close
      elsif !@io.closed?
        @io.close_write
        data = @io.read
        @io.close
      end
      begin
        Process.wait(@pid)
      rescue Errno::ECHILD
      end
      process_reply(data)
    rescue
      $stderr.puts("Caught #{$!.message}")
      raise
    end      

    def process_reply data
      data
    end

    def kill!
      Process.kill('KILL', @pid)
      Process.wait(@pid)
    rescue Errno::ESRCH, Errno::ECHILD
    end
  end

  class ForkedRuby < Forked
    class Error  < RuntimeError
      def initialize kind = 'unknown', message = 'unknown error', bt = nil
        super(message)
      end
    end

    class UnknownError < RuntimeError
      def initialize *args
        super("Unknown error: #{args.inspect}")
      end
    end
    
    def initialize *args, &blk
      super('-', child_args: args) do |this, *args|
        v = blk.call(*args)
        puts(Marshal.dump([ nil, v ]))
        exit!(0)
      rescue Errno::EPIPE
        exit!(2)
      rescue
        $stderr.puts("#{self} caught #{$!.message}", *$!.backtrace)
        begin
          puts(Marshal.dump([ $!.class.name, $!.message, $!.backtrace[0,4] ]))
        rescue
          $stderr.puts("Failed #{$!}")
        end
        exit!(1)
      end
    end

    def process_reply raw_data
      err, data = Marshal.load(raw_data)
      if err == nil
        return data
      elsif err && data
        raise Error.new(err, *data)
      else
        raise UnknownError, raw_data
      end
    end      
  end
end
