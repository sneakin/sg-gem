require_relative 'able'

module SG::Defer
  class Acceptor
    include SG::Defer::Acceptorable
    
    def initialize acc = nil, rej = nil
      @acceptor = acc || :itself.to_proc
      @rejector = rej
    end

    def accept v
      @acceptor.call(v)
    end

    def reject v
      if @rejector
        @rejector.call(v)
      elsif RuntimeError === v
        raise(v)
      else
        v
      end
    end
  end
end
