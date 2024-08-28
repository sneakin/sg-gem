class SG::IO::Reactor
  # todo sources and sinks?
  class Source
    attr_reader :io
    alias to_io io

    def initialize io
      @io = io
    end
    
    def closed?
      io.closed?
    end

    def eof?
      io.eof?
    end

    def tty?
      io.tty?
    end
    
    def needs_processing?
      false
    end
    
    def process
    end
  end

  class IInput < Source
    def needs_processing?; !closed?; end
  end

  class IOutput < Source
  end
end
