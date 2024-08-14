# coding: utf-8
require 'sg/converter'
require 'sg/ext'
require 'sg/algebra'

using SG::Ext

module SG::Units
  class Unit
    include SG::Convertible

    attr_accessor :value

    def initialize v
      self.value = v
    end

    def to_s
      "%s %s" % [ value_string, abbrev ? abbrev : (value.abs <= 1 ? name : name.pluralize) ]
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
      [ Unit.new(other), self ]
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
        k = Class.new(self)
        k.name = name
        k.abbrev = abbrev
        k.dimension = dimension || self.dimension
        k
      end      
    end
    
    class Per < Unit
      class << self
        attr_accessor :numerator
        attr_accessor :denominator
        def name
          "%s / %s" % [ numerator.name, denominator.name ]
        end

        def abbrev
          "%s/%s" % [ numerator.abbrev, denominator.abbrev ]
        end
        
        def dimension
          nil
        end
      end
    end
    
    def self./ other
      k = Class.new(Per)
      k.numerator = self
      k.denominator = other
      k
    end

    class Product < Unit
      class << self
        attr_accessor :base
        attr_accessor :reps

        def name
          super || "%s*%s" % [ base.name, reps.name ]
        end

        def abbrev
          super || "%s*%s" % [ base.abbrev, reps.abbrev ]
        end

        def dimension
          nil
        end
      end
    end
    
    def self.* other
      k = Class.new(Product)
      k.base = self
      k.reps = other
      k
    end

    def abs
      self.class.new(value.abs)
    end
    
    def + other
      other = other.to(self.class)
      self.class.new(value + other.value)
    end

    def -@
      self.class.new(-value)
    end
    
    def - other
      other = other.to(self.class)
      self.class.new(value - other.value)
    end
    
    def * other
      begin
        other = other.to(self.class)
      rescue SG::Converter::NoConverterError, NoMethodError
      end
      if other.kind_of?(Unit)
        k = self.class * other.class
        k.new(value * other.value)
      else
        self.class.new(value * other)
      end
    end

    def / other
      begin
        other = other.to(self.class)
      rescue SG::Converter::NoConverterError, NoMethodError
      end
      if other.kind_of?(Unit)
        new_v = value / other.value
        if self.class == other.class
          new_v
        else
          k = self.class / other.class
          k.new(new_v)
        end
      else
        self.class.new(value / other)
      end
    end
  end

  module TransformedUnit
    def self.included base
      base.extend(ClassMethods)
    end

    def self.derive base, name, abbrev = nil
      k = Class.new(base)
      k.include(self)
      k.name = name
      k.abbrev = abbrev
      k
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
  
  class Dimension < SG::Algebra::Symbol
    def initialize name
      super(name)
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
    
    def self.name
      "second"
    end
  end

  Minute = scaled_unit('minute', Second, 60.0)
  Hour = scaled_unit('hour', Minute, 60.0)
  Day = scaled_unit('day', Hour, 24.0)
  Week = scaled_unit('week', Day, 7.0)
  Year = scaled_unit('year', Day, 365.242)

  Temperature = Dimension.new(:temperature)
  
  class Kelvin < Unit
    self.dimension = Temperature
  end

  Celsius = scaled_unit('Celsius', Kelvin, 1, 273.15)
  Fahrenheit = scaled_unit('Fahrenheit', Celsius, 5/9.0, -32)

  Rotation = Dimension.new(:rotation)
  
  class Radian < Unit
    self.dimension = Rotation
    def self.name
      "radian"
    end
  end

  RotUnit = scaled_unit('rotunit', Radian, Math::PI * 2)
  Degree = scaled_unit('degree', Radian, Math::PI / 180.0)

  Mass = Dimension.new(:mass)
  
  class Gram < Unit
    self.dimension = Mass
    def self.name
      "gram"
    end
  end

  Ounce = scaled_unit('ounce', Gram, 28.3495)
  PoundM = scaled_unit('pound', Ounce, 8)
  
  Velocity = Length / Time
  Acceleration = Velocity / Time
  Force = Mass * Acceleration

  class Newton < Unit
    self.dimension = Force
    def self.name
      'newton'
    end
  end

  Pound = scaled_unit('pound', Newton, 4.44822)

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
      kiba: (1<<10).to_f,
      meba: (1<<20).to_f,
      giba: (1<<30).to_f,
      tiba: (1<<40).to_f,
      peba: (1<<50).to_f
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

    si_prefix :Meter
    si_prefix :Gram
    si_prefix :Liter
    si_prefix :Mole
    si_prefix :Watt
    si_prefix :Joule
    si_prefix :Volt
    si_prefix :Ampere
    si_prefix :Byte
    si_prefix :Bit
  end
end
