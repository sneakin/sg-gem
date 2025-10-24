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

    def with_options **opts, &blk
      yield(OptionApplier.new(self, **opts))
    end
  end

  refine ::Object.singleton_class do
    import_methods WithOptions

    def predicate *names
      raise ArgumentError.new("No predicates named.") if names.empty?
      
      names.each do |n|
        unless String === n || Symbol === n
          raise ArgumentError.new("Predicate names must be String or Symbol, not: #{n.class}")
        end
        class_eval <<-EOT
def #{n}?; !!@#{n}; end
def #{n}!(v=true); @#{n} = v; self; end
def un#{n}!; @#{n} = false; self; end
EOT
      end

      self
    end
    
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

    def identity; self; end
    
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

    def env_flag name, opts = {}
      name = name.to_s
      eval("$%s = ENV[%s].to_bool if ENV.has_key?(%s)" % [ name.downcase, name.upcase.dump, name.upcase.dump ])
    end

    def try meth = nil, *args, **opts, &block
      warn("Deprecated since Ruby added &.")
      if meth
        send(meth, *args, **opts, &block)
      else
        instance_exec(&block)
      end
    end

    def to_bool; true; end

    def true?; true; end
    def false?; false; end
    def blank?; false; end

    def skip_unless test = true, &b
      # Returns an enumerator that calls the following chained method
      # call when `test` is not `nil`. The chained call after that is
      # always called.
      s = SG::SkipUnless.new(test, self, &b)
      s._test_passes?? self : s
    end

    def skip_when test = true, &b
      # Returns an enumerator that calls the following chained method
      # call when `test` is nil or false. The chained call after that
      # is always called.
      s = SG::SkipWhen.new(test, self, &b)
      s._test_passes?? self : s
    end

    def pick *keys
      keys.collect(&method(:[]))
    end

    def pick_attrs *keys
      keys.collect(&method(:send))
    end
  end
end
