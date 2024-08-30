require 'sg/ext'
using SG::Ext

module SG::Units
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
end
