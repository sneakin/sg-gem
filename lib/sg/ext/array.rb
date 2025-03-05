module SG::Ext
  refine Array do
    # Destructively removes one instance of an element.
    def delete_one! term
      i = index(term)
      i ? delete_at(i) : nil
    end

    # Duplicates the array and then deletes one instasce of an element.
    def delete_one term
      i = index(term)
      if i
        dup.tap { |r| r.delete_at(i) }
      else
        self
      end
    end

    # Returns two arrays of `self` and `other` with the
    # shared elements removed.
    def disjunction other
      n = dup
      d = other.dup
      other.each { |t| n.delete_one!(t) && d.delete_one!(t) }
      [ n, d ]
    end
  end
end
