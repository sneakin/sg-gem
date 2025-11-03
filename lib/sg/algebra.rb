require 'sg/constants'

module SG::Algebra
  def self.simplify expr, countdown = 4
    new_expr = expr
    while countdown >= 0
      new_expr = Rules.reduce(expr) { _2.call(_1) }
      break if new_expr == expr
      expr = new_expr
      countdown -= 1
    end
    new_expr
  end

  autoload :Rules, 'sg/algebra/rules'

  module Arithmetic
    def + other
      Addition.new(self, other)
    end

    def - other
      Subtraction.new(self, other)
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

    def | other
      BinOp.new(:|, self, other)
    end

    def & other
      BinOp.new(:&, self, other)
    end

    def ^ other
      BinOp.new(:^, self, other)
    end

    def call env = nil
      self
    end
    
    def method_missing mid, *args, **opts, &cb
      MethodCall.new(self, mid, *args, **opts, &cb)
    end

    def to_ary
      [ self ]
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

    def inspect
      if $verbose
        "(%s[%s] %s %s[%s])" %
          [ left.class, left.inspect,
            op,
            right.class, right.inspect ]
      else
        to_s
      end
    end

    # alias_method :inspect, :to_s

    def call env = nil
      lr = left.respond_to?(:call) ? left.call(env) : left
      rr = right.respond_to?(:call) ? right.call(env) : right
      lr.send(op, rr)
    end

    def eql? other
      other.kind_of?(self.class) &&
        left == other.left &&
        right == other.right
    end

    def == other
      eql?(other)
    end

    def coerce other
      [ Symbol.for(other), self ]
    end
  end
  
  class Addition < BinOp
    def self.op; :+; end

    def self.=== other
      super || (other.kind_of?(BinOp) && op == other.op)
    end
    
    def initialize l, r
      super(:+, l, r)
    end
  end

  class Subtraction < BinOp
    def self.op; :-; end

    def self.=== other
      super || (other.kind_of?(BinOp) && op == other.op)
    end
    
    def initialize l, r
      super(:-, l, r)
    end
  end

  class Product < BinOp
    def self.op; :*; end

    def self.=== other
      super || (other.kind_of?(BinOp) && op == other.op)
    end
    
    def initialize l, r
      super(:*, l, r)
    end
  end

  class Division < BinOp
    def self.op; :/; end

    def self.=== other
      super || (other.kind_of?(BinOp) && op == other.op)
    end

    alias_method :numerator, :left
    alias_method :denominator, :right
    def initialize l, r
      super(:/, l, r)
    end
  end

  class Exponent < BinOp
    def self.op; :**; end

    def self.=== other
      super || (other.kind_of?(BinOp) && op == other.op)
    end

    alias_method :numerator, :left
    alias_method :denominator, :right
    def initialize l, r
      super(:**, l, r)
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

    def call env = nil
      env ? env.fetch(symbol, self) : self
    end

    def eql? other
      other.kind_of?(self.class) && symbol == other.symbol
    end

    def == other
      eql?(other)
    end

    def self.for other
      case other
      when ::Symbol then new(other)
      else Constant.new(other)
      end
    end
    
    def coerce other
      [ self.class.for(other), self ]
    end
  end

  class Constant < Symbol
    def call env = nil
      symbol
    end

    def eql? other
      super || symbol.eql?(other)
    end
  end

  class MethodCall  
    include Arithmetic
    attr_reader :subject, :mid, :args, :opts, :cb
    
    def initialize subject, mid, *args, **opts, &cb
      @subject = subject
      @mid = mid
      @args = args
      @opts = opts
      @cb = cb
    end

    def eql? other
      self.class === other &&
        subject.eql?(other.subject) &&
        mid.eql?(other.mid) &&
        args.eql?(other.args) &&
        opts.eql?(other.opts) &&
        cb.eql?(other.cb)
    end

    def == other
      eql?(other)
    end
      
    def call env = nil
      s = Arithmetic === @subject ? @subject.call(env) : @subject
      arr = args.collect { |a| Arithmetic === a ? a.call(env) : a }
      o = opts.reduce({}) { _1[_2[0]] = Arithmetic === _2[1] ? _2[1].call(env) : _2[1]; _1 }
      if arr.any? { Arithmetic === _1 } || o.any? { Arithmetic === _2 }
        self.class.new(subject, mid, *arr, **o, &cb)
      else
        s.send(mid, *arr, **opts, &cb)
      end
    end

    def coerce other
      [ Symbol.for(other), self ]
    end

    def to_s
      target = case subject
               when Module, Class then subject.name
               when Arithmetic then subject
               end
      if target
        "%s.%s(%s)" % [ target, mid,
                        (args.collect(&:to_s) +
                         opts.collect { "%s: %s" % [ _1, _2 ] }).join(', ')]
      else
        super
      end
    end
  end

  class Builder
    def initialize
    end

    def bop(...)
      BinOp.new(...)
    end

    def build str = nil, &cb
      return str unless str == nil || String === str
      r = nil
      r = instance_eval(str) if str
      r = instance_eval(&cb) if cb
      r
    end

    def method_missing mid, *a, **o, &b
      Symbol.new(mid)
    end
  end
end

def SG.Algebra(...)
  SG::Algebra::Builder.new.build(...)
end
