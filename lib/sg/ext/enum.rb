module SG::Ext
  refine ::Enumerable do
    def blank?; empty?; end

    def rand
      self.drop(Kernel.rand(size)).first
    end

    def branch test, truth, falsehood
      (test ? truth : falsehood).call(self)
    end

    def average
      sum / size.to_f
    end

    def split_at n
      [ first(n), drop(n) ]
    end
  end
end
