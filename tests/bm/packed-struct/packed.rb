require 'sg/packed_struct'

module Runs
  class Packed
    include Run
    
    class TextItem <
          SG::PackedStruct.new([:length, :uint8],
                               [:delta, :int8],
                               [:text, :string, :length])
      calc_attr :length, lambda { self.text.size }
      init_attr :delta, 0
    end

    class PolyText8 < SG::PackedStruct.
      new(
        [:len, :int32],
        [:detail, :int32],
        [:drawable, :int32],
        [:gc, :int32],
        [:x, :int16],
        [:y, :int16],
        [:items, :string, lambda { items ? items.size : ((len ? len : 32) - attribute_offset(:items)) }]    
      )
      init_attr :items, nil
    end

    def name; "PackedStruct"; end

    def struct n
      data = TextItem.new(text: 'Hello')
      r = PolyText8.new(detail: n, len: data.bytesize, x: 100, y: 200, drawable: 20, gc: 123, items: data.pack)
      r.len += r.attribute_offset(:items)
      r
    end

    def write pkt, io
      io.write(pkt.pack)
    end
    
    def reader
      PolyText8
    end

    def read io
      reader.read(io)
    end

    def write_one
      io = StringIO.new
      write(struct(0), io)
      io.string
    end
  end
end
