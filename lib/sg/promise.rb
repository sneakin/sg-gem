require_relative 'defer'

module SG
  module Chainable
    def and_then &cb
      raise NotImplementedError
    end

    def rescues &cb
      raise NotImplementedError
    end

    def ensure &cb
      raise NotImplementedError
    end
    
    def finally &cb
      raise NotImplementedError
    end
  end

  class Promise
    class Acceptor
      include SG::Defer::Acceptorable
      
      def initialize acc = nil, rej = nil
        @acceptor = acc || :itself.to_proc
        @rejector = rej || :itself.to_proc
      end

      def accept v
        @acceptor.call(v)
      end

      def reject v
        @rejector.call(v)
      end
    end
    
    include SG::Chainable

    def initialize &fn
      @fn = fn
    end

    def call acceptor = nil
      @fn.call(acceptor || Acceptor.new)
    end

    def and_then &cb
      Promise.new do |acc|
        call(Acceptor.new(lambda { acc.accept(cb.call(_1)) },
                          lambda { acc.reject(_1) }))
      end
    end

    def rescues &cb
      Promise.new do |acc|
        call(Acceptor.new(lambda { acc.accept(_1) },
                          lambda { acc.accept(cb.call(_1)) }))
      end
    end

    def ensure &cb
      Promise.new do |acc|
        call(Acceptor.new(lambda { acc.accept(cb.call(_1)) },
                          lambda { acc.reject(cb.call(_1)) }))
      end
    end
    
    def finally &cb
      Promise.new { |acc| cb.call(call(Acceptor.new)) }
    end
  end

  class PromisedValue < Promise
    def initialize v
      super() do |acc|
        acc.accept(v.wait)
      rescue
        acc.reject($!)
      end
    end
  end
end
