module SG::Ext
  refine ::Hash do
    def symbolize_keys
      self.class[self.collect { |k, v| [ k.to_sym, v ] }]
    end
    
    def stringify_keys
      self.class[self.collect { |k, v| [ k.to_s, v ] }]
    end

    def stringify_values
      self.class[self.collect { |k, v| [ k, v.to_s ] }]
    end
  end
end
