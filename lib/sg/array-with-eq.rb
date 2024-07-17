module SG
  class ArrayWithEq < ::Array
    def find other
      super() do |el|
        el === other
      end
    end
    
    def include? other
      !find(other).nil?
    end
    
    def === other
      include?(other)
    end
  end
end
