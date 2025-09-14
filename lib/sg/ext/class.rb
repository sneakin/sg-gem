module SG::Ext
  refine ::Class do
    def subclasses
      ObjectSpace.each_object.
        select { |o| o.class.equal?(Class) && o.superclass.equal?(self) }
    end

    def all_subclasses top = true
      r = subclasses + subclasses.collect { |s| s.all_subclasses(false) }
      top ? r.flatten : r
    end

    def subclasses? klass
      return true if superclass.equal?(klass)
      return false if superclass.nil?
      (ancestors & klass.ancestors).find { |el| el.equal?(klass) } != nil
    end
  end
end
