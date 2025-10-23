require 'sg/ext'
using SG::Ext

# `case` clause helpers.
module SG::Is
  # Give classes a {[]} class method for construction and conversion.
  module NewBracket
    # todo did add the SG::Ext::Class#[]
    module ClassMethods
      def [](...)
        new(...)
      end
    end

    def self.included base
      base.extend(ClassMethods)
    end
  end

  # Combines SG::Is classes using operators and other common functionality.
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

    def to_str; to_s; end
    def to_proc; lambda { self === _1 }; end
  end

  # The logical AND of multiple LogicOps.
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

  # The logical OR of multiple LogicOps.
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

  # The logical negation of a LogicOp.
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

  # Provides LogicOps for the left handed side of a {#===}.
  class CaseOf
    include NewBracket

    def initialize lhs
      @lhs = lhs
    end

    def === other
      @lhs === other
    end

    include LogicOps
  end

  # Provides LogicOps for the right handed side of a {#===}.
  class InCaseOf
    include NewBracket

    def initialize rhs
      @rhs = rhs
    end

    def === other
      other === @rhs
    end

    include LogicOps
  end

  # Tests with a Boolean returning block argument or named method.
  class Predicated
    include NewBracket

    def initialize fn = nil, *a, **o, &blk
      if blk
        @fn = blk
        @args = [ *fn, *a ]
      else
        @fn = fn.skip_when(&CaseOf[Proc]).to_proc
        @args = a
      end
      @opts = o
    end

    def === other
      @fn.call(*[other, *@args], **@opts)
    end

    include LogicOps
  end

  # For cases when an array has a value.
  class Included < Predicated
    def initialize arr
      super() { arr.include?(_1) }
    end
  end

  # For cases when a value is in an array.
  class MemberOf < Predicated
    def initialize arr
      super(:include?, arr)
    end
  end
  
  # Checking for methods in cases:
  class ResponsiveTo < Predicated
    def initialize meth
      super(:respond_to?, meth)
    end
  end
end
