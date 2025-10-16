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
    
    include SG::Chainable

    def initialize fn = nil, &blk
      @fn = fn || blk
      @fn ||= lambda { |acc, *args| acc.accept(args[0]) }
    end

    def to_proc
      lambda { |*a| self.call(nil, *a) }
    end
    
    def call *args
      acceptor = args[0]
      unless SG::Defer::Acceptorable === acceptor
        args.unshift(acceptor = Acceptor.new)
      end
      @fn.call(*args)
    rescue
      acceptor.reject($!)
    end

    def new_sibling *a, **o, &blk
      Promise.new(*a, **o, &blk)
    end
    
    def and_then &cb
      return self unless cb
      new_sibling do |acc, *args|
        call(Acceptor.new(lambda { acc.accept(cb.call(_1, *args)) },
                          lambda { acc.reject(_1) }),
             *args)
      end
    end

    def rescues &cb
      return self unless cb
      new_sibling do |acc, *args|
        call(Acceptor.new(lambda { acc.accept(_1) },
                          lambda { acc.accept(cb.call(_1, *args)) }),
             *args)
      end
    end

    def ensure &cb
      return self unless cb
      new_sibling do |acc, *args|
        call(Acceptor.new(lambda { acc.accept(cb.call(_1, *args)) },
                          lambda { acc.reject(cb.call(_1, *args)) }),
             *args)
      end
    end

    # todo what's this do other than ensure and wanting freezing?
    def finally &cb
      return self unless cb
      new_sibling do |acc, *args|
        v = call(Acceptor.new, *args)
        acc.accept(cb.call(v, *args))
      rescue
        begin
          acc.reject(cb.call($!, *args))
        rescue
          raise
        end
      end
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
