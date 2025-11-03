require 'sg/skip-unless'

module SG::Ext
  module WithOptions
    class OptionApplier
      def initialize target, **opts
        @target = target
        @opts = opts
      end

      def method_missing mid, *a, **o, &b
        @target.send(mid, *a, **@opts.merge(o), &b)
      end
    end

    # Yields a proxy object that merges the supplied keyword options to
    # any method calls.
    #
    # @example
    #   with_options(x: 123, y: 456) do |w|
    #     w.merge({ z: 789 })
    #   end # => { x: 123, y: 456, z: 789 }
    #
    # @param [Hash] opts The pairs to merge.
    def with_options **opts, &blk
      yield(OptionApplier.new(self, **opts))
    end
  end

  refine ::Object.singleton_class do
    import_methods WithOptions

    # Define question and exclamation marked methods to access a
    # boolean instance variable.
    #
    # @param [Array<String, Symbol>] names
    # @param read_only [Boolean] Set to prevent setters.
    # @return [self]
    # @raise [ArgumentError]
    def predicate *names, read_only: false
      raise ArgumentError.new("No predicates named.") if names.empty?
      
      names.each do |n|
        unless String === n || Symbol === n
          raise ArgumentError.new("Predicate names must be String or Symbol, not: #{n.class}")
        end
        class_eval <<-EOT
def #{n}?; !!@#{n}; end
EOT
        class_eval <<-EOT unless read_only
def #{n}!(v=true); @#{n} = v; self; end
def un#{n}!; @#{n} = false; self; end
EOT
      end

      self
    end

    # Forward method call through a method.
    # @param [Array<Symbol, String>] methods
    # @param [Symbol] to The target method.
    # @return [void]
    def delegate(*methods, to:)
      raise ArgumentError.new("No delegates were named.") if methods.empty?

      methods.each do |m|
        unless String === m || Symbol === m
          raise ArgumentError.new("Delegate names must be String or Symbol, not: #{n.class}")
        end
        # Ruby did not like assignments of `...`
        if m.to_s[-1] == '=' && m[-2] != ']'
          class_eval <<-EOT
def #{m}(v)
  self.#{to}.#{m}(v)
end
EOT
        else
          class_eval <<-EOT
def #{m}(...)
  self.#{to}.#{m}(...)
end
EOT
        end
      end
      self
    end

    # Class attributes that subclasses can change for their family.
    # @param [Array<Symbol>] attrs The new attributes to generate.
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
  end

  refine ::Object do
    import_methods WithOptions

    def identity
      warn("Deprecation warning: use Object#itself:", *caller_locations[0, 3])
      self
    end
    
    def try meth = nil, *args, **opts, &block
      warn("Deprecated since Ruby added &.", *caller_locations[0, 3])
      if meth
        send(meth, *args, **opts, &block)
      else
        instance_exec(&block)
      end
    end

    # Become truthy.
    def to_bool; true; end

    # Objects are truthy.
    def true?; true; end
    # Objects are not falsey.
    def false?; false; end
    # Objects are no blanks.
    def blank?; false; end

    # Globals initialized from ENV.
    def env_flag name, opts = {}
      name = name.to_s
      eval("$%s = ENV[%s].to_bool if ENV.has_key?(%s)" %
           [ name.downcase, name.upcase.dump, name.upcase.dump ])
    end

    # Returns an proxy that calls the following chained method
    # call when `test` is not `nil`. The chained call after that is
    # always called.
    #
    # @example
    #   'foo'.skip_unless(true).upcase.each_char.first # => 'F'
    #   'bar'.skip_unless(false).upcase.each_char.first # => 'b'
    def skip_unless test = true, &b
      s = SG::SkipUnless.new(test, self, &b)
      s._test_passes?? self : s
    end

    # Returns an proxy that calls the following chained method
    # call when `test` is nil or false. The chained call after that
    # is always called.
    #
    # @example
    #   'foo'.skip_when(true).upcase.each_char.first # => 'f'
    #   'bar'.skip_when(false).upcase.each_char.first # => 'B'
    def skip_when test = true, &b
      s = SG::SkipWhen.new(test, self, &b)
      s._test_passes?? self : s
    end

    # Collect the {#[]} values for the given keys.
    # @param [Array<Symbol>] keys
    # @return [Enumerable]
    def pick *keys
      keys.collect(&method(:[]))
    end

    # Collect the values for the given methods.
    # @param [Array<Symbol>] names
    # @return [Enumerable]
    def pick_attrs *names
      names.collect(&method(:send))
    end

    # Dig down the attributes calling each attribute on the returned value.
    # @return [Object]
    def dig *attrs
      attrs.reduce(self) { _1.send(_2) }
    end
  end
end
