class SG::IO::Reactor
  class Port
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

    def close
      self
    end
    
    def process
      self
    end
  end
end
