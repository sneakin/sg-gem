require_relative 'port'

class SG::IO::Reactor
  class Source < Port
    def needs_processing?; !closed?; end
  end
end
