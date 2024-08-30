require 'sg/ext'
using SG::Ext

module SG::Units
  class Dimension
    attr_reader :name
    
    def initialize name
      #super(name)
      @name = name
    end
    
    def self.dimension?
      self.superclass == Dimension
    end

    def self.dimension
      if dimension?
        return self
      elsif superclass != Object
        superclass.dimension
      end
    end

    def invert
      Per.new(NullDimension, self)
    end

    def coerce other
      # fixme hmm
      [ NullDimension, self ]
    end

    def * other
      # a * 1
      return self if other == 1 || other == NullDimension
      # a * x/a
      return other.numerator if Per === other && self == other.denominator
      # avoid products with any Per
      return Per.new(self * other.numerator, other.denominator) if Per === other
      Product.new(self, other)
    end

    def / other
      # a / 0
      raise ZeroDivisionError if other == 0
      # a / 1
      return self if other == 1 || other == NullDimension
      # a / a
      return NullDimension if self == other
      # a / a/x
      return other.denominator if Per === other && self == other.numerator
      
      Per.new(self, other)
    end

    def eql? other
      Dimension === other && name == other.name
    end

    alias == eql?
    
    def to_s
      name
    end
    
    def inspect
      "#<Dimension:%s>" % [ name ]
    end

    class Per < Dimension
      attr_accessor :numerator, :denominator
      def initialize n, d
        @numerator = n
        @denominator = d
        super("#{n.name}/#{d.name}")
      end

      def eql? other
        self.class === other &&
          numerator.eql?(other.numerator) &&
          denominator.eql?(other.denominator)
      end

      alias == eql?
      
      def * other
        # a/b * b => a
        return numerator if denominator == other
        # a/b * x/a => x/b
        return other.numerator / denominator if Per === other && numerator == other.denominator
        return Per.new(numerator * other, denominator)
      end

      def / other
        # a/b / 1/b => a
        return numerator / other.numerator if Per === other && denominator == other.denominator
        # a/b / a => a/b * 1/a => 1/b
        return NullDimension / denominator if numerator == other
        # a/b / a/x => a/b * x/a => x/b
        return other.numerator / denominator if Per === other && numerator == other.numerator
        return Per.new(numerator.delete(other), denominator) if Product === numerator && numerator.include?(other)
        return Per.new(numerator, denominator * other)
      end
    end

    class Product < Dimension
      attr_reader :terms
      def initialize *terms
        @terms = terms
        super(terms.collect(&:name).join('*'))
      end

      def eql? other
        self.class === other &&
          terms.eql?(other.terms)
      end

      alias == eql?
      
      def include? term
        terms.include?(term)
      end
      
      def delete term
        i = terms.index(term)
        if i
          new_terms = terms.dup
          new_terms.delete_at(i)
          (new_terms.size > 1 ? Product.new(*new_terms) : new_terms[0]) || NullDimension
        else
          self
        end
      end
      
      def cancel other
        if Product === other
          n, d = terms.disjunction(other.terms)
          if d.empty?
            if n.size < 2
              n.first || NullDimension
            else
              Product.new(*n)
            end
          else
            Per.new(Product.new(*n), Product.new(*d))
          end
        elsif include?(other)
          delete(other)
        else
          Per.new(self, other)
        end
      end

      def / other
        # a*b / x*y
        return cancel(other) if Product === other
        # a*b / b => a
        # a*b / a => b
        return delete(other) if terms.include?(other)
        # a*b / b/x => a/x
        return delete(other.numerator) * other.denominator if Per === other && terms.include?(other.numerator)
        # a*b / b/y
        return Per.new(self * other.denominator, other.numerator) if Per === other
        # a*b * X
        return Per.new(self, other)        
      end

      def * other
        # a*b * x/a => x*b
        return delete(other.denominator) * other.numerator if Per === other && terms.include?(other.denominator)
        return Product.new(*terms, *other.terms) if Product === other
        return Product.new(*terms, other)
      end
    end
  end

  class ANullDimension < Dimension
    def invert
      self
    end

    def * other
      other
    end

    def / other
      other.invert
    end
  end
  
  NullDimension = ANullDimension.new(:null)
end
