module SG::Ext
  refine ::Integer do
    def count_bits
      raise ArgumentError.new("Number must be positive") if self < 0
      n = self
      count = 0
      while n > 0
        count += 1 if n & 1 == 1
        n = n >> 1
      end
      count
    end

    def to_bitmask
      raise ArgumentError.new("Number must be >= 1") if self < 1
      (1 << (Math.log2(self).floor + 1)) - 1
    end
    
    def nth_byte byte
      (self >> (byte * 8)) & 0xFF
    end
    
    # @todo unused
    def revbits bits = 32
      bits.times.reduce(0) do |a, i|
        a | (((self >> i) & 1) << (bits-1-i))
      end
    end      
  end
end
