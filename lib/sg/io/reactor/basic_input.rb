class SG::IO::Reactor
  class BasicInput < Source
    # @param io [IO]
    # @param reactor [Reactor]
    # @return [BasicInput]
    # @yield [void]
    # @yieldreturn [String]
    def self.read(io, reactor: nil, &blk)
      reactor ||= SG::IO::Reactor.current
      rin = self.new(io) do
        begin
          data = blk.call
          reactor.delete(rin)
          data
        rescue IO::WaitReadable, IO::WaitWritable
          # reactor will try again
        rescue
          reactor.delete(rin)
          raise
        end
      end
      reactor << rin
      rin
    end

    def initialize io, &cb
      super(io)
      @cb = cb
    end

    def needs_processing?; !closed?; end

    def process
      @cb.call
    end
  end
end
