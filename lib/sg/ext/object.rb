require 'sg/skip-unless'

module SG::Ext
  refine ::Object.singleton_class do
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
  end

  refine ::Object do
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
      SG::SkipUnless.new(test, self, &b)
    end

    def skip_when test = false, &b
      # Returns an enumerator that calls the following chained method
      # call when `test` is nil or false. The chained call after that
      # is always called.
      SG::SkipUnless.new(!test, self, &b&.not)
    end

    def pick *keys
      keys.collect(&method(:[]))
    end

    def pick_attrs *keys
      keys.collect(&method(:send))
    end
  end
end
