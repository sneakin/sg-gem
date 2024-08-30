require 'sg/ext'
using SG::Ext

module SG::Units
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
end
