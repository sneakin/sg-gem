require_relative 'defer'

module SG
  module Chainable
    def resolve(acceptor, ...)
      acceptor.accept(...)
    end
    
    def new_sibling &blk
      raise NotImplementedError
    end

    def and_then &cb
      return self unless cb
      new_sibling do |acc, *args|
        resolve(SG::Defer::Acceptor.new(lambda { acc.accept(cb.call(_1, *args)) },
                                        lambda { acc.reject(_1) }),
                *args)
      end
    end

    def rescues &cb
      return self unless cb
      new_sibling do |acc, *args|
        resolve(SG::Defer::Acceptor.new(lambda { acc.accept(_1) },
                                        lambda { acc.accept(cb.call(_1, *args)) }),
                *args)
      end
    end

    def ensure &cb
      return self unless cb
      new_sibling do |acc, *args|
        resolve(SG::Defer::Acceptor.new(lambda { acc.accept(cb.call(_1, *args)) },
                                        lambda { acc.reject(cb.call(_1, *args)) }),
                *args)
      end
    end

    def and_tap &cb
      return self unless cb
      new_sibling do |acc, *args|
        resolve(SG::Defer::Acceptor.new(lambda { cb.call(_1, *args); acc.accept(_1) },
                                        lambda { cb.call(_1, *args); acc.reject(_1) }),
                *args)
      end
    end
  end

  class Promise
    include SG::Chainable

    def initialize fn = nil, &blk
      @fn = fn || blk
      @fn ||= lambda { |acc, *args| acc.accept(args[0]) }
    end

    def to_proc
      lambda { |*a, **o, &b| self.call(*a, **o, &b) }
    end
    
    def call(...)
      resolve(SG::Defer::Acceptor.new, ...)
    end

    def resolve(acceptor, ...)
      @fn.call(acceptor, ...)
    rescue
      acceptor.reject($!)
    end

    def new_sibling &blk
      Promise.new(&blk)
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
