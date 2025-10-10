# @todo needs processing needs to be redone
class SG::IO::Reactor
  class BasicOutput < Sink
    # @param io [IO]
    # @param reactor [Reactor]
    # @return [BasicInput]
    # @yield [void]
    # @yieldreturn [String]
    def self.write(io, reactor: nil, &blk)
      reactor ||= SG::IO::Reactor.current
      rout = self.new(io, needs_processing: lambda { true }) do
        begin
          cnt = blk.call
          reactor.delete(rout)
          cnt
        rescue IO::WaitReadable, IO::WaitWritable
          # reactor will try again
        rescue
          reactor.delete(rout)
          raise
        end
      end
      reactor << rout
      rout
    end

    def initialize io, needs_processing: nil, &cb
      raise ArgumentError.new('no block given') if cb == nil
      super(io)
      @cb = cb
      @needs_processing = needs_processing
    end

    def needs_processing?
      @needs_processing.call if @needs_processing
    end

    def close
      io.close
      super
    end
    
    def process
      @cb.call
    end
  end
end
