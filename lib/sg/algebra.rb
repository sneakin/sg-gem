require 'sg/constants'

module SG::Algebra
  module Arithmetic
    def + other
      BinOp.new(:+, self, other)
    end

    def - other
      BinOp.new(:-, self, other)
    end

    def / other
      Division.new(self, other)
    end
    
    def * other
      Product.new(self, other)
    end

    def ** other
      BinOp.new(:**, self, other)
    end

    def call env
      self
    end
    
    def method_missing mid, *args, **opts, &cb
      MethodCall.new(self, mid, args, opts, cb)
    end
  end
  
  class BinOp
    include Arithmetic
    
    attr_accessor :op
    attr_accessor :left
    attr_accessor :right
    
    def initialize op, l, r
      @op = op
      @left = l
      @right = r
    end
    
    def to_s
      "(%s %s %s)" % [ left, op, right ]
    end

    alias_method :inspect, :to_s
    
    def call env
      lr = left.respond_to?(:call) ? left.call(env) : left
      rr = right.respond_to?(:call) ? right.call(env) : right
      lr.send(op, rr)
    end

    def == other
      other.kind_of?(self.class) &&
        left == other.left &&
        right == other.right
    end

    def coerce other
      [ Symbol.for(other), self ]
    end
  end
  
  class Product < BinOp
    def initialize l, r
      super(:*, l, r)
    end
  end

  class Division < BinOp
    alias_method :numerator, :left
    alias_method :denominator, :right
    def initialize l, r
      super(:/, l, r)
    end
  end

  class Symbol
    include Arithmetic

    attr_reader :symbol
    
    def initialize sym
      @symbol = sym
    end

    def to_s
      symbol.to_s
    end
    
    alias_method :inspect, :to_s

    def call env
      env.fetch(symbol, self)
    end

    def == other
      other.kind_of?(self.class) && symbol == other.symbol
    end

    def self.for other
      case other
      when Symbol.new(other)
      else Constant.new(other)
      end
    end
    
    def coerce other
      [ self.class.for(other), self ]
    end
  end

  class Constant < Symbol
    def call env
      symbol
    end
  end

  class MethodCall  
    include Arithmetic
    attr_reader :subject, :mid, :args, :opts, :cb
    
    def initialize subject, mid, args, opts, cb
      @subject = subject
      @mid = mid
      @args = args
      @opts = opts
      @cb = cb
    end
      
    def call env
      s = Arithmetic === @subject ? @subject.call(env) : @subject
      s.send(mid,
             *args.collect { |a| Arithmetic === a ? a.call(env) : a },
             **opts, &cb)
    end

    def coerce other
      [ Symbol.for(other), self ]
    end
  end
end
