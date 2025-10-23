require 'bindata'

module Runs
  class BinData
    include Run
    
    class Record < ::BinData::Record
      endian :little
    end
    
    class TextItem < Record
      uint8 :len, value: lambda { bytesize - 2 }
      int8 :delta
      string :text, read_length: :len

      def bytesize; 2 + text.bytesize; end
    end
  
    class PolyText8 < Record
      int32 :len, value: lambda { items.rel_offset + items.collect(&:bytesize).sum }
      int32 :detail    
      int32 :drawable
      int32 :gc
      int16 :x
      int16 :y
      array :items, type: TextItem, read_length: lambda { (len - items.rel_offset) }
      #skip :final_padding, length: X11RB::Protocol::BinData.final_padder, read_length: X11RB::Protocol::BinData.final_padding_reader
    end

    def name; "BinData"; end
    
    def struct n
      data = TextItem.new(text: 'Hello')
      PolyText8.new(detail: n, drawable: 20, gc: 123, x: 100, y: 200, items: [ data ])
    end

    def write pkt, io
      pkt.write(io)
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
