require 'sg/rescued_proc'

module SG::Ext::Proc
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
    SG::RescuedProc.new(self, *exes, &cb)
  end
end
