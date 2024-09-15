module SG::Ext
  refine ::Hash do
    def symbolize_keys
      self.reduce(self.class.new) do |h, (k, v)|
        h[k.to_sym] = v
        h
      end
    end
    
    def stringify_keys
      self.reduce(self.class.new) do |h, (k, v)|
        h[k.to_s] = v
        h
      end
    end

    def stringify_values
      self.reduce(self.class.new) do |h, (k, v)|
        h[k] = v.to_s
        h
      end
    end
  end
end
