require 'thread'
require 'openssl'

class SG::IO::Reactor
  class QueuedOutput < IOutput
    def initialize io, &cb
      super(io)
      @queue = []
      @cb = cb || lambda { |pkt| io.write_nonblock(pkt) }
      @closing = false
    end

    def close
      @closing = true
      self
    end

    alias close_write close

    def closed?
      @closing == true || super
    end
    
    def flush
      self
    end
    
    def << data
      @queue << data
      self
    end

    def write data
      @queue << data
      data.size
    end

    alias write_nonblock write
    
    def puts *lines
      if lines.empty?
        write("\n")
        lines
      else
        lines.each { |l| write(l.to_s + "\n") }
      end
    end

    def queue_empty?; @queue.empty?; end
    
    def needs_processing?
      !@queue.empty?
    end

    def process
      amt = 0
      data = nil
      while !@queue.empty?
        data = @queue.shift
        amt = 0 # for when exceptions happen
        amt = @cb.call(data)
        @queue.unshift(data[amt..-1]) if amt < data.size
      end

      if @closing && !io.closed?
        io.close
        @closing = nil
      end
    rescue ::IO::WaitWritable, ::OpenSSL::SSL::SSLErrorWaitWritable
      @queue.unshift(data[amt..-1]) if data && amt < data.size
    rescue Errno::EPIPE
      # fixme necessary? more cases?
      io.close
      @closing = nil
    end
  end
end
