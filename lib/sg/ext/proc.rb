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

    def dup
      super.tap do
        _1.inner_fn = inner_fn
        _1.error_handlers = error_handlers.dup
      end
    end
      
    # Exception rescue clauses:
      
    attr_accessor :inner_fn
    attr_writer :error_handlers

    def error_handlers
      @error_handlers ||= Hash.new
    end

    def error_handler_for ex
      unless ex.kind_of?(Class)
        ex = ex.class
      end
      handler = [ ex, *ex.ancestors ].
        find { |c| error_handlers.has_key?(c) }
      error_handlers[handler] || raise(KeyError.new(ex))
    end
    
    def err! ex
      error_handler_for(ex).call(ex)
    rescue KeyError
      raise ex
    end

    public
    def but *exceptions, &cb
      return self if exceptions.empty? && cb == nil
      # The original Proc needs to be tracked since dupping the Proc
      # would not update ~p~ in ~p.errs!~.
      this = self
      unless (error_handlers.empty? && error_handlers.default == nil) || this.inner_fn == nil
        this = this.inner_fn
      end
      p = lambda do |*a, **o, &b|
        this.call(*a, **o, &b)
      rescue
        p.err!($!)
      end.tap do
        _1.inner_fn = this
        _1.error_handlers = self.error_handlers.dup
      end.but!(*exceptions, &cb)
    end
    
    def but! *exceptions, &cb
      if exceptions.empty?
        error_handlers.default = cb
      else
        exceptions.each { error_handlers[_1] = cb }
      end

      self
    end
  end
end
