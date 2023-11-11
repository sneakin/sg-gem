module SG::Ext
  refine ::Integer do
    def count_bits
      n = self
      count = 0
      while n > 0
        count += 1 if n & 1 == 1
        n = n >> 1
      end
      count
    end

    def nth_byte byte
      (self >> (byte * 8)) & 0xFF
    end
    
    # todo unused
    def self.revbits bits = 32
      bits.times.reduce(0) do |a, i|
        a | (((self >> i) & 1) << (bits-1-i))
      end
    end      
  end
end
