module SG::Ext
  refine ::Numeric do
    def rand
      Kernel.rand(self)
    end
  end
end
