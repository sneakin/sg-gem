require_relative 'defer'

module SG
  module Chainable
    def and_then &cb
    end

    def rescues &cb
    end

    def finally &cb
    end
  end

  class Chain
    include Chainable

    def initialize acceptor = nil, rejector = nil, &cb
      @acceptor = acceptor || cb
      @rejector = rejector
    end

    def accept v
      @acceptor ? @acceptor.call(v) : return v
    rescue
      reject($!)
    end

    def reject v
      @rejector ? @rejector.call(v) : return(v)
    end
    
    def and_then &cb
      self.class.new(lambda { cb.call(accept(_1)) },
                     lambda { reject(_1) })
    end

    def rescues &cb
      self.class.new(lambda { accept(_1) },
                     lambda { accept(cb.call(_1)) })
    end
  end

  class PromiseGold
    def initialize &fn
      @fn = fn
    end

    def call acc = nil, rej = nil
      @fn.call(acc || :itself.to_proc, rej || :itself.to_proc)
    end

    def and_then &cb
      PromiseGold.new do |acc, rej|
        call(lambda { acc.call(cb.call(_1)) }, rej)
      end
    end

    def rescues &cb
      PromiseGold.new do |acc, rej|
        call(acc, lambda { acc.call(cb.call(_1)) })
      end
    end

    def finally &cb # or always
      PromiseGold.new do |acc, rej|
        call(lambda { acc.call(cb.call(_1)) },
             lambda { rej.call(cb.call(_1)) })
      end
    end
  end

  # class PromisedValue < PromiseGold
  #   def initialize v
  #     super() do |acc, rej|
  #       acc.call(v.wait)
  #     rescue
  #       rej.call($!)
  #     end
  #   end
  # end

  class Promise2
    class Acceptor
      include SG::Defer::Acceptorable
      
      attr_reader :acceptor, :rejector
      
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
    
    def initialize &fn
      @fn = fn
    end

    def call acceptor = nil
      @fn.call(acceptor || Acceptor.new)
    end

    def and_then &cb
      Promise2.new do |acc|
        call(Acceptor.new(lambda { acc.accept(cb.call(_1)) },
                          lambda { acc.reject(_1) }))
      end
    end

    def rescues &cb
      Promise2.new do |acc|
        call(Acceptor.new(lambda { acc.accept(_1) },
                          lambda { acc.accept(cb.call(_1)) }))
      end
    end

    def finally &cb
      Promise2.new(lambda { acc.accept(cb.call(_1)) },
                   lambda { acc.accept(cb.call(_1)) })
    end
      
  end

  class PromisedValue < Promise2
    def initialize v
      super() do |acc|
        acc.accept(v.wait)
      rescue
        acc.reject($!)
      end
    end
  end
  
  class Promise
    include SG::Defer::Able
    
    def initialize future, acceptor = nil, rejector = nil
      @acceptor = acceptor
      @rejector = rejector
      @future = future
      @our_future = Defer::Value.new do
        v = @future.wait
        @acceptor ? @acceptor.call(v) : v
      rescue
        @rejector ? @rejector.call($!) : raise
      end
    end

    def wait
      @our_future.wait
    end
    
    def resolve ok, err
      err ? reject(err) : accept(ok)
    end
    
    def accept v
      @future.accept(v)
    end

    def reject v
      @future.reject(v)
    end

    def reset!
      @future.reset!
      @our_future.reset!
      self
    end
    
    def and_then &fn
      Promise.new(self, fn, nil)
    end

    def rescues &fn
      Promise.new(self, nil, fn)
    end
  end
end
