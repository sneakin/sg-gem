module SG::Ext
  refine ::Proc do
    # todo Use Ruby's #curry
    
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

    def fn= v
      @fn = v
    end

    def fn
      @fn || self
    end

    def and &cb
      compose(cb)
    end

    def not
      lambda { |*a, **o, &b| !self.call(*a, **o, &b) }
    end

    alias ~ not

      # todo adding an on_error method for an alt route?
    def on_error
      @on_error ||= Hash.new
    end

    def err! ex
      clause = [ ex.class, *ex.class.ancestors ].
        find { on_error.has_key?(_1) }
      h = on_error[clause]
      raise ex unless h
      h.call(ex)
    end

    def but *exceptions, &cb
      return self if exceptions.empty? && cb == nil
      p = lambda do |*a, **o, &b|
        self.call(*a, **o, &b)
      rescue
        p.err!($!)
      end.but!(*exceptions, &cb)
    end
    
    def but! *exceptions, &cb
      if exceptions.empty?
        @en_error = Hash.new { cb.call(_2) }.merge!(on_error)
      else
        exceptions.each { on_error[_1] = cb }
      end

      self
    end
  end
end
