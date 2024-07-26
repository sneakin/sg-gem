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
  end
end
