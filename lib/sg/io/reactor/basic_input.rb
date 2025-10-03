class SG::IO::Reactor
  class BasicInput < Source
    # @param io [IO]
    # @param reactor [Reactor]
    # @return [BasicInput]
    # @yield [void]
    # @yieldreturn [String]
    def self.read(io, reactor: nil, &blk)
      reactor ||= SG::IO::Reactor.current
      rin = SG::IO::Reactor::BasicInput.new(io) do
        begin
          data = blk.call
          reactor.delete(rin)
          data
        rescue EOFError
          reactor.delete(rin)
          raise
        rescue IO::EAGAINWaitReadable
          # reactor will try again
        end
      end
      reactor << rin # todo deleting the IO requires rin since the reactor IO is unavailable
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
