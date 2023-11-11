module SG::Ext::ClassMethods
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
