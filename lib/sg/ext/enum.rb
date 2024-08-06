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

    def aggregate initials, &fn
      reduce(initials) do |acc, row|
        row.zip(acc).collect do |el, el_acc|
          fn.call(el_acc, el)
        end
      end
    end

    def nth n, count = nil
      d = drop(n)
      if count
        d.first(count)
      else
        d.first
      end
    end

    def second count = nil; nth(1, count); end
    def third count = nil; nth(2, count); end
    def fourth count = nil; nth(3, count); end
  end
end
