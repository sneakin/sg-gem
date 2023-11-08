class Proc
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

  def and &cb
    compose(cb)
  end

  attr_accessor :on_error, :fn

  def fn
    @fn || self
  end
  
  def but *exes, &cb
    return self unless cb
    
    this = self
    other = self.class.new do |*a, **o, &b|
      begin
        this.call(*a, **o, &b)
      rescue
        if exes.empty? || exes.include?($!.class)
          other.on_error.call($!)
        else
          raise
        end
      end
    end
    other.fn = this
    other.on_error = cb
    other
  end
  
end
