require 'sg/ext'
using SG::Ext

# `case` clause helpers.
module SG::Is
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
    include NewBracket

    def initialize *cases
      @cases = cases
    end

    def === other
      @cases.all? { |c| c === other }
    end

    def to_s
      "%s[%s]" % [ self.class.name, cases.collect(&:to_s).join(', ') ]
    end

    include LogicOps
  end

  class Or
    include NewBracket

    def initialize *cases
      @cases = cases
    end

    def === other
      @cases.any? { |c| c === other }
    end

    def to_s
      "%s[%s]" % [ self.class.name, cases.collect(&:to_s).join(', ') ]
    end

    include LogicOps
  end

  class Not
    include NewBracket

    def initialize pred
      @pred = pred
    end

    def === other
      !(@pred === other)
    end

    def to_s
      "%s[%s]" % [ self.class.name, @pred ]
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
