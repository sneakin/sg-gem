module SG::Units
  class Bit < Counted
    self.dimension = Dimension.new(:bit_count)
  end
  
  Byte = scaled_unit('byte', Bit, 8)
  Short = scaled_unit('short', Bit, 16)
  Long = scaled_unit('long', Bit, 32)
end
