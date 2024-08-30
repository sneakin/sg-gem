module SG::Ext
  refine Array do
    def delete_one! term
      i = index(term)
      i ? delete_at(i) : nil
    end

    def delete_one term
      i = index(term)
      if i
        dup.tap { |r| r.delete_at(i) }
      else
        self
      end
    end

    def disjunction other
      n = dup
      d = other.dup
      other.each { |t| n.delete_one!(t) && d.delete_one!(t) }
      [ n, d ]
    end
  end
end
