require 'sg/ext'
using SG::Ext

module SG::Is
  module LogicOps
    def &(other)
      And[self, other]
    end

    def |(other)
      Or[self, other]
    end

    def ~
        Not[self]
    end
  end
  
  class And
    def self.[] *cases
      new(*cases)
    end

    def initialize *cases
      @cases = cases
    end

    def === other
      @cases.all? { |c| c === other }
    end

    include LogicOps
  end

  class Or
    def self.[] *cases
      new(*cases)
    end

    def initialize *cases
      @cases = cases
    end

    def === other
      @cases.any? { |c| c === other }
    end

    include LogicOps
  end

  class Not
    def self.[] p
      new(p)
    end

    def initialize pred
      @pred = pred
    end

    def === other
      !(@pred === other)
    end

    include LogicOps
  end

  class Predicated
    def self.[] fn = nil, &blk
      new(&(blk || fn))
    end

    def initialize &blk
      @fn = blk
    end

    def === other
      @fn === other
    end

    include LogicOps
  end

  module NewBracket
    module ClassMethods
      def [] *a, **o, &cb
        new(*a, **o, &cb)
      end
    end

    def self.included base
      base.extend(ClassMethods)
    end
  end
  
  class ResponsiveTo
    include NewBracket

    def initialize meth
      @meth = meth
    end

    def === other
      other.respond_to?(@meth)
    end

    include LogicOps
  end
end
