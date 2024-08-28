class SG::IO::Reactor
  class BasicInput < Source
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
