# coding: utf-8
require 'sg/converter'
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
      "#<%s: %s>" % [ name, value ]
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
      [ Unitless.new(other), self ]
    end
    
    class << self
      attr_accessor :dimension
      alias_method :classname, :name
      
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
    end

    class Per < Unit
      class << self
        attr_accessor :numerator
        attr_accessor :denominator
        def name
          "%s / %s" % [ numerator.name.blank? ? '1' : numerator.name,
                        denominator.name.blank? ? '1' : denominator.name
                      ]
        end

        def abbrev
          "%s/%s" % [ numerator.abbrev.blank? ? '1' : numerator.abbrev,
                      denominator.abbrev.blank? ? '1' : denominator.abbrev
                      ]
        end
        
        def dimension
          unless @dimension
            nd = (Unit === numerator) ? numerator.dimension : NullDimension
            dd = (Unit === denominator) ? denominator.dimension : NullDimension
            @dimension ||= (nd == dd) ? NullDimension : nd / dd
          end

          @dimension
        end

        def * other
          # a/b * b => a
          return numerator if denominator == other
          # a/b * x/a => x/b
          return other.numerator / denominator if other.superclass == Per && numerator == other.denominator
          super(other)
        end

        def / other
          # a/b / 1/b => a
          return numerator / other.numerator if other.superclass == Per && denominator == other.denominator
          # a/b / a => a/b * 1/a => 1/b
          return Unitless / denominator if numerator == other
          # a/b / a/x => a/b * x/a => x/b
          return other.numerator / denominator if other.superclass == Per && numerator == other.numerator
          super(other)
        end

        def invert
          @invert ||= numerator == Unitless ? denominator : derive(denominator, numerator)
        end
        
        def derive n, d
          Class.new(Per).tap do |per|
            per.numerator = n
            per.denominator = d
          end
        end

      end
    end

    def self./ other
      return Unitless if self == other
      return self if other == 1 || other == Unitless
      # A / A/x => x
      return other.denominator if other.superclass == Per && self == other.numerator
      # A / Ab => 1 / b
      return Per.derive(Unitless, other.base) if Product === other && self == other.reps
      return Per.derive(Unitless, other.reps) if Product === other && self == other.base
      
      this = self
      @per_cache ||= Hash.new do |h, k|
        h[k] = Per.derive(this, k)
      end
      @per_cache[other]
    end

    def self.invert
      @invert ||= Per.derive(Unitless, self)
    end
    
    class Product < Unit
      class << self
        attr_accessor :base
        attr_accessor :reps

        def name
          super || [ base.name, reps.name ].reject(&:blank?).join('*')
        end

        def abbrev
          super || [ base.abbrev, reps.abbrev ].reject(&:blank?).join('*')
        end

        def dimension
          @dimension ||= base.dimension * reps.dimension
        end

        def / other
          # a*b / b => a
          return base if reps == other
          # a*b / a => b
          return reps if base == other
          # a*b / b/x => a/x
          return base / other.denominator if other.superclass == Per && reps == other.numerater
          # a*b / a/x => b/x
          return reps / other.denominator if other.superclass == Per && base == other.numerater
          
          super(other)
        end

        def * other
          # a*b * x/a => x*b
          return other.numerator * reps if other.superclass == Per && base == other.denominator
          # a*b * x/b => a*x
          return base * other.numerator if other.superclass == Per && reps == other.denominator
          super(other)
        end

        def derive base, reps
          Class.new(Product).tap do |p|
            p.base = base
            p.reps = reps
          end
        end
      end
    end
    
    def self.* other
      return self if other == 1 || other == Unitless
      return other.numerator if other.superclass == Per && self == other.denominator
      
      this = self
      @product_cache ||= Hash.new do |h, k|
        h[k] = Product.derive(this, k)
      end
      @product_cache[other]
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

  module TransformedUnit
    def self.included base
      base.extend(ClassMethods)
    end

    def self.derive base, name, abbrev = nil
      Class.new(base).tap do |u|
        u.include(self)
        u.name = name
        u.abbrev = abbrev
        u.dimension = base.dimension
      end
    end
    
    module ClassMethods
      def name
        @name
      end

      def abbrev
        @abbrev
      end
    end
  end

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
      [ NullDimension, self ]
    end
    
    def * other
      # a * 1
      return self if other == 1 || other == NullDimension
      # a * x/a
      return other.numerator if Per === other && self == other.denominator
      Product.new(self, other)
    end

    def / other
      # a / 1
      return self if other == 1 || other == NullDimension
      # a / 0
      return NullDimension if other == 0 || other == NullDimension
      # a / a
      return NullDimension if self == other
      # a / a/x
      return other.denominator if Per === other && self == other.numerator
      
      Per.new(self, other)
    end

    def eql? other
      Dimension === other && name == other.name
    end

    def to_s
      name
    end
    
    class Per < Dimension
      attr_accessor :numerator, :denominator
      def initialize n, d
        @numerator = n
        @denominator = d
        super("#{n.name}/#{d.name}")
      end

      def * other
        # a/b * b => a
        return numerator if denominator == other
        # a/b * x/a => x/b
        return other.numerator / denominator if Per === other && numerator == other.denominator
        super(other)
      end

      def / other
        # a/b / 1/b => a
        return numerator / other.numerator if Per === other && denominator == other.denominator
        # a/b / a => a/b * 1/a => 1/b
        return NullDimension / denominator if numerator == other
        # a/b / a/x => a/b * x/a => x/b
        return other.numerator / denominator if Per === other && numerator == other.numerator
        super(other)
      end
    end

    class Product < Dimension
      attr_accessor :base, :reps
      def initialize b, r
        @base = b
        @reps = r
        super("#{b.name}*#{r.name}")
      end

      def / other
        # a*b / b => a
        return base if reps == other
        # a*b / a => b
        return reps if base == other
        # a*b / b/x => a/x
        return base / other.denominator if Per === other && reps == other.numerater
        # a*b / a/x => b/x
        return reps / other.denominator if Per === other && base == other.numerater
        
        super(other)
      end

      def * other
        # a*b * x/a => x*b
        return other.numerator * reps if Per === other && base == other.denominator
        # a*b * x/b => a*x
        return base * other.numerator if Per === other && reps == other.denominator
        super(other)
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

  class Unitless < Unit
    self.dimension = NullDimension
    self.name = ''
    self.abbrev = ''

    def + other
      case other
      when Unit then super(other)
      else value + other
      end
    end
    
    def - other
      case other
      when Unit then super(other)
      else value - other
      end
    end
    
    def * other
      case other
      when Unit then other.class.new(value * other.value)
      else super(other) #value * other
      end
    end
    
    def / other
      case other
      when Unit then other.class.invert.new(value / other.value)
      else super(other) #value / other
      end
    end
    
    def == other
      value == other || super(other)
    end
    def eql? other
      value.eql?(other) || super(other)
    end

    delegate :to_s, :to_i, :to_f, :to_r, to: :value

    def coerce other
      [ other, value ]
    end

    def inspect
      '#<%s: %s>' % [ 'Unitless', value.inspect ]
    end
  end
  
  def self.transformed_unit name, base, from_conv, to_conv = nil, abbrev: nil
    k = TransformedUnit.derive(base, name, abbrev)
    factor = from_conv
    unless from_conv.kind_of?(Proc)
      if to_conv == nil
        to_conv = lambda { |b| base.new(b.value * factor) }
      end
      from_conv = lambda { |b| k.new(b.value / factor) }
    end
    if to_conv != nil && !to_conv.kind_of?(Proc)
      to_conv = lambda { |b| base.new(b.value * to_conv) }
    end
    if to_conv
      SG::Converter.register(k, base, &to_conv)
    end
    SG::Converter.register(base, k, &from_conv)
    k
  end

  def self.scaled_unit name, base, factor, offset = 0, abbrev: nil
    k = TransformedUnit.derive(base, name, abbrev)
    SG::Converter.register_scaler(k, base, factor, offset)
    k
  end
  
  Length = Dimension.new(:length)

  class Meter < Unit
    self.dimension = Length

    def self.name
      super || "meter"
    end

    def self.abbrev
      super || name[0]
    end
  end

  Inch = scaled_unit('inch', Meter, 0.0254, abbrev: 'in')
  Foot = scaled_unit('foot', Inch, 12.0)
  Yard = scaled_unit('yard', Foot, 3.0)
  Mile = scaled_unit('mile', Foot, 5280.0)

  Area = Length * Length
  Meter2 = Meter * Meter
  Meter2.name = 'meter²'
  Meter2.abbrev = 'm²'
  Meter2.dimension = Area
  Volume = Length * Area
  Meter3 = Meter * Meter * Meter
  Meter3.name = 'meter³'
  Meter3.abbrev = 'm³'
  Meter3.dimension = Volume
  Liter = scaled_unit('liter', Meter3, 1e-3)
  
  Time = Dimension.new(:time)

  class Second < Unit
    self.dimension = Time
    self.name = 'second'
    self.abbrev = 's'
  end

  Minute = scaled_unit('minute', Second, 60.0)
  Hour = scaled_unit('hour', Minute, 60.0)
  Day = scaled_unit('day', Hour, 24.0)
  Week = scaled_unit('week', Day, 7.0)
  Year = scaled_unit('year', Day, 365.242)

  # todo frequency as 1 / time [in a medium?]
  Frequency = Dimension.new(:frequency)

  class Hertz < Unit
    self.dimension = Frequency
    self.name = 'hertz'
    self.abbrev = 'Hz'
  end

  #Hertz = transformed_unit('hertz', Second, lambda { |x| 1 / x })

  Temperature = Dimension.new(:temperature)
  
  class Kelvin < Unit
    self.dimension = Temperature
    self.name = 'Kelvin'
    self.abbrev = 'K'
  end

  Celsius = scaled_unit('Celsius', Kelvin, 1, 273.15)
  Fahrenheit = scaled_unit('Fahrenheit', Celsius, 5/9.0, -32)

  Rotation = Dimension.new(:rotation)
  
  class Radian < Unit
    self.dimension = Rotation
    self.name = "radian"
    self.abbrev = 'r'
  end

  RotUnit = scaled_unit('rotunit', Radian, Math::PI * 2)
  Degree = scaled_unit('degree', Radian, Math::PI / 180.0, abbrev: '°')

  # todo seconds -> degrees -> miles [on a planet?]
  
  Mass = Dimension.new(:mass)
  
  class Gram < Unit
    self.dimension = Mass
    self.name = 'gram'
    self.abbrev = 'g'
  end

  Ounce = scaled_unit('ounce', Gram, 28.3495, abbrev: 'oz')
  PoundM = scaled_unit('pound', Ounce, 8, abbrev: 'lbs')
  
  Velocity = Length / Time
  Acceleration = Velocity / Time
  Force = Mass * Acceleration

  class Newton < Unit
    self.dimension = Force
    self.name = 'newton'
    self.abbrev = 'N'
  end

  Pound = scaled_unit('pound', Newton, 4.44822, abbrev: 'lbs')

  Count = Dimension.new(:count)
  
  class Counted < Unit
    self.dimension = Count
  end

  Mole = scaled_unit('mole', Counted, 6.02214076e23)
  
  Energy = Force * Length
  Joule = Newton * Meter
  Power = Energy * Time
  Watt = Joule * Second

  Charge = Dimension.new(:charge)

  class ElectronCount < Unit
    self.dimension = Charge
  end
  Columb = scaled_unit('Columb', ElectronCount, 6.241509074e18)

  EPotential = Energy / Charge
  Current = Charge / Time
  PowerV = EPotential * Current

  Volt = Joule / Columb
  Ampere = Columb / Second
  Ohm = Volt / Ampere
  PowerVsi = Volt * Ampere

  class Bit < Counted
    self.dimension = Count
  end
  
  Byte = scaled_unit('byte', Bit, 8)
  Short = scaled_unit('short', Bit, 16)
  Long = scaled_unit('long', Bit, 32)
  
  module SI
    Prefixes = {
      '' => 1,
      deci: 1e-1,
      deca: 1e1,
      centi: 1e-2,
      hecto: 1e2,
      milli: 1e-3,
      kilo: 1e3,
      micro: 1e-6,
      mega: 1e6,
      nano: 1e-9,
      giga: 1e9,
      pico: 1e-12,
      tera: 1e12,
      femto: 1e-15,
      peta: 1e15,
      atto: 1e-18,
      exa: 1e18,
      zepto: 1e-21,
      zetta: 1e21,
      yocto: 1e-24,
      yotta: 1e24,
      ronto: 1e-27,
      ronna: 1e27,
      quecto: 1e-30,
      quetta: 1e30,
      kiba: (1 << 10).to_f,
      meba: (1 << 20).to_f,
      giba: (1 << 30).to_f,
      tiba: (1 << 40).to_f,
      peba: (1 << 50).to_f
    }
    
    def self.si_prefix unit_s
      unit_s = unit_s.to_s
      unit_n = unit_s.camelize
      unit = const_get("SG::Units::#{unit_n}")
      Prefixes.each do |prefix, scale|
        const_set("#{prefix.to_s.camelize}#{unit_n}",
                  SG::Units.scaled_unit("#{prefix}#{unit_s.downcase}", unit, scale))
      end
    end

    %w{ Meter Second Hertz Gram
        Liter Mole Newton Watt Joule
        Volt Ampere Ohm Byte Bit
    }.each(&method(:si_prefix))
  end
end
