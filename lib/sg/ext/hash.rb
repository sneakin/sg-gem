module SG::Ext
  refine ::Hash do
    # Converts the keys into symbols using #to_sym.
    def symbolize_keys
      self.reduce(self.class.new) do |h, (k, v)|
        h[k.to_sym] = v
        h
      end
    end

    # Converts the keys into strings using #to_s.
    def stringify_keys
      self.reduce(self.class.new) do |h, (k, v)|
        h[k.to_s] = v
        h
      end
    end

    # Converts all of the values into strings using #to_s.
    def stringify_values
      self.reduce(self.class.new) do |h, (k, v)|
        h[k] = v.to_s
        h
      end
    end
  end
end
