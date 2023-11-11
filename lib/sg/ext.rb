module SG
  module Ext
  end
end

require_relative 'ext/class'
require_relative 'ext/object'
require_relative 'ext/nil'
require_relative 'ext/module'
require_relative 'ext/string'
require_relative 'ext/enum'
require_relative 'ext/numeric'
require_relative 'ext/integer'
require_relative 'ext/io'
require_relative 'ext/hash'
require_relative 'ext/proc'

module SG
  module Ext
    def self.monkey_patch!
      ::Class.include(SG::Ext::ClassMethods)
      ::Object.include(SG::Ext::Object)
      ::Module.include(SG::Ext::Mod)
      ::NilClass.include(SG::Ext::Nil)
      ::FalseClass.include(SG::Ext::Nil)
      ::String.include(SG::Ext::String)
      ::String.include(SG::Ext::Enum)
      ::Enumerable.include(SG::Ext::Enum)
      ::Numeric.include(SG::Ext::Numeric)
      ::Integer.include(SG::Ext::Integer)
      ::IO.include(SG::Ext::IO)
      ::Proc.include(SG::Ext::Proc)
      ::Hash.include(SG::Ext::Hash)
    end

    refine ::Class do
      include SG::Ext::ClassMethods
      include SG::Ext::Object
    end

    refine ::Object.singleton_class do
      include SG::Ext::Object::ClassMethods
    end

    refine ::Object do
      include SG::Ext::Object
    end

    refine ::Module do
      include SG::Ext::Mod
    end

    refine ::NilClass do
      include SG::Ext::Nil
    end

    refine ::FalseClass do
      include SG::Ext::Nil
    end

    refine ::String do
      include SG::Ext::Enum
      include SG::Ext::String
    end

    refine ::Enumerable do
      include SG::Ext::Enum
    end

    refine ::Numeric do
      include SG::Ext::Numeric
    end

    refine ::Integer do
      include SG::Ext::Integer
    end

    refine ::IO do
      include SG::Ext::IO
    end

    refine ::Proc do
      include SG::Ext::Proc
    end

    refine ::Hash do
      include SG::Ext::Hash
    end
  end
end

