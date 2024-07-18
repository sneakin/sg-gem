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

    def permutate_with variants, acc = [], &cb
      #return to_enum(__method__, variants) unless cb
      unless cb
        # work around refinement semantics
        return Enumerator.new do |yielder|
          permutate_with(variants) do |p|
            yielder << p
          end
        end
      end
      
      if size == 0
        if acc.size > 0
          cb.call(acc)
        end
      else
        head = first
        variants.each do |v|
          drop(1).permutate_with(variants, acc + [ v.to_proc.call(head) ], &cb)
        end
      end
    end
  end
end
