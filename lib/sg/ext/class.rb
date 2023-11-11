module SG::Ext
  refine ::Class do
    def subclasses
      ObjectSpace.each_object.
        select { |o| o.class == Class && o.superclass == self }
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
end
