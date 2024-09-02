require 'sg/ext'
using SG::Ext

module SG::Units
  class DimensionMismatch < TypeError
    def initialize a, b
      super("#{a.inspect} != #{b.inspect}")
    end
  end
  
  class Unit
    include Comparable
    include SG::Convertible

    attr_accessor :value

    def initialize v
      self.value = v
    end

    def to_s
      "%s %s" %
        [ value_string,
          abbrev ? abbrev : (value.abs <= 1 ? name : name.pluralize)
        ]
    end

    def inspect
      "#<%s: %s>" % [ name.camelize, value ]
    end
    
    def name
      self.class.name
    end

    def abbrev
      self.class.abbrev
    end

    def value_string
      value.to_s
    end

    def coerce other
      if Unit === other
        [ other, self ]
      else
        [ Unitless.new(other), self ]
      end
    end
    
    class << self
      alias_method :classname, :name

      attr_accessor :dimension
      def dimension
        @dimension || (superclass != Object ? superclass&.dimension : nil)
      end
      
      attr_writer :name
      def name
        @name ||= self.classname&.split('::')&.[](-1)
      end

      attr_writer :abbrev
      def abbrev
        @abbrev
      end

      def derive name, abbrev = nil, dimension = nil
        Class.new(self).tap do |u|
          u.name = name
          u.abbrev = abbrev
          u.dimension = dimension || self.dimension || Dimension.new(name)
        end
      end

      def inspect
        "#<Unit:%s:%s>" % [ dimension&.name, name ]
      end

      def eql? other
        dimension == other.dimension &&
          name == other.name &&
          abbrev == other.abbrev
      rescue NoMethodError
        false
      end

      def coerce other
        if Unit === other
          [ other, self ]
        else
          [ Unitless, self ]
        end
      end
    end

    class Per < Unit
      inheritable_attr :numerator
      inheritable_attr :denominator

      class << self
        def name
          @name ||= "%s / %s" %
            [ numerator.name.blank? ? '1' : numerator.name,
              denominator.name.blank? ? '1' : denominator.name
            ]
        end
        
        def abbrev
          @abbrev ||= "%s/%s" %
            [ numerator.abbrev.blank? ? '1' : numerator.abbrev,
              denominator.abbrev.blank? ? '1' : denominator.abbrev
            ]
        end
        
        def * other
          # a/b * b => a
          return numerator if denominator == other
          if other.subclasses?(Per)
            # a/b * x/a => x/b
            return other.numerator / denominator if numerator == other.denominator
            # a/b * x/y
            return (numerator * other.numerator).cancel(denominator * other.denominator)
          end
          # a/b * x => ax/b
          return derive(numerator * other, denominator)
        end

        def / other
          # a/b / a => a/b * 1/a => 1/b
          return Unitless / denominator if numerator == other
          if other.subclasses?(Per)
            # a/b / 1/b => a
            return numerator / other.numerator if denominator == other.denominator
            # a/b / a/x => a/b * x/a => x/b
            return other.numerator / denominator if numerator == other.numerator
          end
          # a/b / xa => x/b
          return Per.derive(numerator.delete(other), denominator) if numerator.subclasses?(Product) && numerator.include?(other)
          # a/b / x => a/bx
          return Per.derive(numerator, denominator * other)
        end

        def invert
          @invert ||= numerator == Unitless ? denominator : derive(denominator, numerator)
        end

        def per_cache
          @per_cache ||= Hash.new
        end
        
        def derive n, d
          # n = n.first if Array === n && n.size == 1
          # n = n.terms.first if n.subclasses?(Product) && n.terms.size == 1
          # d = d.first if Array === d && d.size == 1
          # d = d.terms.first if d.subclasses?(Product) && d.terms.size == 1

          key = [n, d]
          cached = per_cache[key]
          return cached if cached
          
          per_cache[key] ||= Class.new(Per).tap do |per|
            per.numerator = n
            per.denominator = d
            per.dimension = n.dimension / d.dimension
          end
        end

      end
    end

    # todo units of the same dimension: scaler+unit?
    
    def self./ other
      raise ZeroDivisionError if other == 0
      # A/A
      return Unitless if self == other
      # A/1
      return self if other == 1 || other == Unitless
      # A / Ab => 1 / b
      return Per.derive(Unitless, other.delete(self)) if other.subclasses?(Product) && other.include?(self)
      if other.subclasses?(Per)
        # A / A/x => x
        return other.denominator if self == other.numerator
        # A / x/y => A*y / x
        return Per.derive(self * other.denominator, other.numerator)
      end
      # A / x
      Per.derive(self, other)
    end

    def self.invert
      @invert ||= Per.derive(Unitless, self)
    end
    
    class Product < Unit
      inheritable_attr :terms

      class << self
        def name
          @name ||= terms.collect(&:name).reject(&:blank?).join('*')
        end
        
        def abbrev
          @abbrev ||= terms.collect(&:abbrev).reject(&:blank?).join('*')
        end
        
        def delete term
          nt = terms.delete_one(term)
          if terms.equal?(nt)
            self
          else
            (nt.size > 1 ? Product.derive(*nt) : nt[0]) || UnitLess
          end
        end

        def cancel other
          if other.subclasses?(Product)
            n, d = terms.disjunction(other.terms)
            if d.empty?
              if n.size < 2
                n.first || Unitless
              else
                Product.derive(*n)
              end
            else
              n = n.size > 1 ? Product.derive(*n) : n.first
              d = d.size > 1 ? Product.derive(*d) : d.first
              Per.derive(n, d)
            end
          elsif include?(other)
            delete(other)
          else
            Per.derive(self, other)
          end
        end

        def include? term
          terms.include?(term)
        end
        
        def / other
          raise ZeroDivisionError if other == 0
          # a / a
          return Unitless if self == other
          # a*b / x*y
          return cancel(other) if other.subclasses?(Product)
          # a*b / b => a
          # a*b / a => b
          return delete(other) if terms.include?(other)
          if other.subclasses?(Per)
            # a*b / b/x => a/x
            # a*b / a/x => b/x
            return delete(other) * other.denominator if terms.include?(other.numerater)
            # ab / abxyz
            #return cancel(other) if other.subclasses?(Product)
            # a*b / x/y => a*b*y/x
            return Per.derive(self * other.denominator, other.numerator)
          end
          # a*b / x
          return Per.derive(self, other)
        end

        def * other
          if other.subclasses?(Per)
            # a*b * x/a => x*b
            # a*b * x/b => a*x
            return delete(other.denominator) * other.numerator if terms.include?(other.denominator)
            # a*b / x/y => aby/x
            return Per.derive(self * other.denominator, other.numerator)
          end
          # a*b * x*y
          return derive(*other.terms) if other.subclasses?(Product)
          # a*b * x
          return derive(other)
        end

        def product_cache
          @product_cache ||= Hash.new
        end

        # todo is returning seconds for seconds*seconds
        def derive *new_terms
          all_terms = ((terms || []) + (new_terms || [])).freeze
          return Unitless if all_terms.empty?
          raise ArgumentError, 'single term product' if all_terms.size < 2
          #return all_terms[0] if all_terms.size == 1 && all_terms[0].subclasses?(Unit)
          cached = product_cache[all_terms]
          return cached if cached
          product_cache[all_terms] ||= Class.new(Product).tap do |p|
            p.terms = all_terms
            p.dimension = all_terms.
              collect(&:dimension).
              reduce(SG::Ignored.new, &:*)
          end
        end
      end
    end
    
    def self.* other
      # A * 0
      return Unitless if other == 0
      # A * 1
      return self if other == 1 || other == Unitless
      if other.subclasses?(Per)
        # A * x/A
        return other.numerator if self == other.denominator
        # A * x/y
        return Per.derive(self * other.numerator, other.denominator)
      end
      # A * xyz
      return Product.derive(self, *other.terms) if other.subclasses?(Product)
      # A * x
      Product.derive(self, other)
    end

    def same_dimension? other
      Unit === other &&
        self.class.dimension == other.class.dimension
    end

    def check_dimension! other
      if Unit === other
        if !same_dimension?(other)
          raise DimensionMismatch.new(self.class.dimension, other.class.dimension)
        end
      else
        raise DimensionMismatch.new(self.class.dimension, other.class)
      end
    end

    def nan?
      value.nan?
    end
    
    def abs
      self.class.new(value.abs)
    end
    
    def +@
      self
    end
    
    def -@
      self.class.new(-value)
    end
    
    def + other
      check_dimension!(other)
      other = other.to(self.class)
      self.class.new(value + other.value)
    end

    def - other
      check_dimension!(other)
      other = other.to(self.class)
      self.class.new(value - other.value)
    end
    
    def * other
      other = other.to(self.class) if same_dimension?(other)
      if other.kind_of?(Unit)
        (self.class * other.class).new(value * other.value)
      else
        self.class.new(value * other)
      end
    end

    def / other
      other = other.to(self.class) if same_dimension?(other)
      if other.kind_of?(Unit)
        (self.class / other.class).new(value / other.value)
      else
        self.class.new(value / other)
      end
    end

    def invert
      self.class.invert.new(1 / value)
    end
    
    def <=> other
      check_dimension!(other)
      return value <=> other.to(self.class).value if self.class === other
      return self.to(other.class).value <=> other.value if other.class === self
      raise TypeError.new("Incomparable: #{self.class} <=> #{other.class}")
    end

    def eql? other
      return false if !same_dimension?(other)
      return value.eql?(other.to(self.class).value) if self.class === other
      return self.to(other.class).value.eql?(other.value) if other.class === self
      raise TypeError.new("Incomparable: #{self.class}.eql?(#{other.class})")
    end

    # alias == eql?
    def == other
      return false if !same_dimension?(other)
      return value == other.to(self.class).value if self.class === other
      return self.to(other.class).value == other.value if other.class === self
      raise TypeError.new("Incomparable: #{self.class} == #{other.class}")
    end
    
    alias eq? ==

  end
end
