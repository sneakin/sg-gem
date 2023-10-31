module SG
  module Ext
    module ClassMethods
      unless Object.method_defined?(:subclasses)
        def subclasses
          ObjectSpace.each_object.
            select { |o| o.class == Class && o.superclass == self }
        end
      end

      def all_subclasses top = true
        r = subclasses + subclasses.collect { |s| s.all_subclasses(false) }
        top ? r.flatten : r
      end

      def subclasses? klass
        return true if superclass == klass
        return false if superclass == nil
        superclass.subclasses?(klass)
      end
    end

    module Nil
      def try meth = nil, *args, &block
        nil
      end

      def blank?; true; end

      def to_bool; false; end
    end
    
    module Object
      def recurse(m, top = true)
        r = send(m)
        if r
          r = r + r.collect { |o| o.recurse(m, false) }
          if top
            r.flatten
          else
            r
          end
        end
      end

      def delegate(*methods, to:)
        methods.each do |m|
          class_eval <<-EOT
def #{m} *args, **opts, &cb
  self.#{to}.#{m}(*args, **opts, &cb)
end
EOT
        end
      end
      
      def inheritable_attr *attrs
        attrs.each do |a|
          define_singleton_method(a) do
            nil
          end
          define_singleton_method("#{a}=") do |val|
            define_singleton_method(a) do
              val
            end
          end
        end
      end

      def const_by_value n
        constants.find { |c| const_get(c) == n }
      end

      def to_bool; true; end
    end

    module Mod
      def mattr_accessor *attrs
        attrs.each do |attr|
          module_eval <<-EOT
def self.#{attr}
  @#{attr}
end
def self.#{attr}= v
  @#{attr} = v
end
EOT
        end
      end

      def xinheritable_attr *attrs
        attrs.each do |attr|
          module_eval <<-EOT
module Attributes
  def #{attr}
    nil
  end
  def #{attr}= val
    define_singleton_method(#{attr.inspect}) do
      val
    end
  end
end
extend(Attributes)
EOT
        end
      end
    end
    
    module Instance
      def env_flag name, opts = {}
        name = name.to_s
        eval("$%s = ENV[%s].to_bool if ENV.has_key?(%s)" % [ name.downcase, name.upcase.dump, name.upcase.dump ])
      end

      def try meth = nil, *args, &block
        if meth
          send(meth, *args, &block)
        else
          instance_exec(&block)
        end
      end

      def blank?; false; end
    end

    module String
      def pluralize
        case self
        when 'foot' then 'feet'
        when /(.*)[aoeui]y$/ then self + "s"
        when /(.*[^aoeui])y$/ then $1 + "ies"
        when /ch$/ then self + 'es'
        when /(.*[^f])f$/ then $1 + 'ves'
        when /(.*[^f])fe$/ then $1 + 'ves'
        when /[^s]$/ then self + 's'
        else self
        end
      end

      def titleize
        if size > 0
          self[0].upcase + self[1..-1]
        else
          self
        end
      end

      def camelize
        # capitalize and join the words
        gsub(/[[:upper:]]+/) { |m| m.capitalize }.
          gsub(/((?:^|\s+|[-_]+)[[:lower:]]+)/) { |m| m = m.gsub(/[-_]|\s/, ''); "%s%s" % [ m[0].upcase, m[1..-1].downcase ] }
      end

      def underscore
        # replace case transitions, spaces, and hyphens with underscores
        gsub(/[[:upper:]]+/) { |m| m.capitalize }.
          gsub(/(\s|-)+/, '_').
          gsub(/((?:^|[[:lower:]])[[:upper:]])/) { |m| m[1] ? "%s_%s" % [ m[0].downcase, m[1].downcase ] : m.downcase }
      end

      def to_bool
        !(self =~ /^((no*)|(f(alse)?)|0*$)/i)
      end
    end

    module Enum
      def blank?; empty?; end

      def rand
        self.drop(Kernel.rand(size)).first
      end

      def branch test, truth, falsehood
        (test ? truth : falsehood).call(self)
      end

      def average
        sum / size.to_f
      end
    end

    module Numeric
      def rand
        Kernel.rand(self)
      end
    end
    
    module Integer
      def count_bits
        n = self
        count = 0
        while n > 0
          count += 1 if n & 1 == 1
          n = n >> 1
        end
        count
      end
    end

    module IO
      def read_until chars, chomp: true
        r = ''
        while (c = getc) && !chars.include?(c)
          r << c
        end
        r << c unless chomp
        r
      rescue EOFError
        r
      end
    end

    module Proc
      def * other
        if other || other != 1
          lambda { |*args| other.call(self.call(*args)) }
        else
          self
        end
      end
    end    
  end
end

Class.include(SG::Ext::ClassMethods)
Object.extend(SG::Ext::Object)
Object.include(SG::Ext::Instance)
#Module.include(SG::Ext::Object)
Module.include(SG::Ext::Mod)
NilClass.include(SG::Ext::Nil)
FalseClass.include(SG::Ext::Nil)
String.include(SG::Ext::String)
String.include(SG::Ext::Enum)
Enumerable.include(SG::Ext::Enum)
Numeric.include(SG::Ext::Numeric)
Integer.include(SG::Ext::Integer)
IO.include(SG::Ext::IO)
Proc.include(SG::Ext::Proc)

