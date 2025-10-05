require_relative 'port'

class SG::IO::Reactor
  class Source < Port
    def close
      io.close
      super
    end
    
    def needs_processing?; !closed?; end
  end
end
