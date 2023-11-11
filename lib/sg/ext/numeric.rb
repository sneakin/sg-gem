module SG::Ext::Numeric
  def rand
    Kernel.rand(self)
  end
end
