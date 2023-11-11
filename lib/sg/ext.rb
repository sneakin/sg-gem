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
      def try meth = nil, *args, **opts, &block
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
def #{m}(...)
  #{to}.#{m}(...)
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

      def const_by_value n
        constants.find { |c| const_get(c) == n }
      end
    end
    
    module Instance
      def env_flag name, opts = {}
        name = name.to_s
        eval("$%s = ENV[%s].to_bool if ENV.has_key?(%s)" % [ name.downcase, name.upcase.dump, name.upcase.dump ])
      end

      def try meth = nil, *args, **opts, &block
        if meth
          send(meth, *args, **opts, &block)
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

      def split_at n
        [ self[0, n], self[n, size - n] ]
      end

      def strip_controls
        gsub(/[\x00-\x1F]+/, '')
      end
      
      def strip_escapes
        gsub(/(\e\[?[-0-9;]+[a-zA-Z])/, '')
      end

      def strip_display_only
        strip_escapes.strip_controls
      end

      def screen_size
        # size minus the escapes and control codes with double width chars counted twice
        #VisualWidth.measure(strip_display_only)
        strip_escapes.display_width
      end

      def visual_slice len
        if screen_size < len
          [ self, nil ]
        else
          part = ''
          width = 0
          in_escape = false
          each_char do |c|
            if width >= len
              break
            end
            if c == "\e"
              in_escape = true
            elsif in_escape && (Range.new('a'.ord, 'z'.ord).include?(c.ord) || Range.new('A'.ord, 'Z'.ord).include?(c.ord))
              in_escape = false
            elsif !in_escape
              width += Unicode::DisplayWidth.of(c)
            end
            part += c
          end
          return [ part, self[part.size..-1] ]
        end
      end
      
      def each_visual_slice n, &cb
        return to_enum(__method__, n) unless cb

        if screen_size < n
          cb.call(self)
        else
          rest = self
          begin
            sl, rest = rest.visual_slice(n)
            cb.call(sl)
          end while(rest && !rest.empty?)
        end

        self
      end
      
      def truncate len
        visual_slice(len).first
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

      def split_at n
        [ first(n), drop(n) ]
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

      def nth_byte byte
        (self >> (byte * 8)) & 0xFF
      end
      
      # todo unused
      def self.revbits bits = 32
        bits.times.reduce(0) do |a, i|
          a | (((self >> i) & 1) << (bits-1-i))
        end
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
      def partial_before *args
        self.class.new do |*a, **o, &b|
          self.call(*args, *a, **o, &b)
        end
      end

      def partial_after *args
        self.class.new do |*a, **o, &b|
          self.call(*a, *args, **o, &b)
        end
      end
      
      def partial_options **opts
        self.class.new do |*a, **o, &b|
          self.call(*a, **o.merge(opts), &b)
        end
      end
      
      def partial_defaults **opts
        self.class.new do |*a, **o, &b|
          self.call(*a, **opts.merge(o), &b)
        end
      end
      
      def compose other
        self.class.new do |*a, **o, &b|
          other.call(self.call(*a, **o, &b))
        end
      end

      alias * compose

      def and &cb
        compose(cb)
      end

      attr_accessor :on_error

      def fn= v
        @fn = v
      end

      def fn
        @fn || self
      end

      def but *exes, &cb
        return self unless cb
        RescuedProc.new(self, *exes, &cb)
      end
    end

    class RescuedProc < ::Proc
      attr_reader :fn, :on_error, :exceptions
      
      def initialize fn, *exceptions, &cb
        super(&fn)
        @fn = fn
        @exceptions = exceptions
        @on_error = cb
      end

      def call *a, **o, &cb
        @fn.call(*a, **o, &cb)
      rescue
        if @exceptions.empty? || @exceptions.include?($!.class)
          @on_error.call($!)
        else
          raise
        end
      end
    end
    
    module Hash
      def symbolize_keys
        self.class[self.collect { |k, v| [ k.to_sym, v ] }]
      end
      def stringify_keys
        self.class[self.collect { |k, v| [ k.to_s, v ] }]
      end
    end
    
    def self.monkey_patch!
      ::Class.include(SG::Ext::ClassMethods)
      ::Object.extend(SG::Ext::Object)
      ::Object.include(SG::Ext::Instance)
      #::Module.include(SG::Ext::Object)
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
      include SG::Ext::Object
    end

    refine ::Object do
      include SG::Ext::Instance
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

