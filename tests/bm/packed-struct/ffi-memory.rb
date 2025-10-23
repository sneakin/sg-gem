require 'ffi'

module Runs
  class FFIMemory
    include Run
    
    module HashInit
      def initialize data = nil, **attrs
        super(data || FFI::Buffer.new(128))
        attrs.each { self[_1.to_sym] = _2 }
      end

      def []= attr, value
        if Array === value
          value.each_with_index { self[attr][_2] = _1 }
        else
          super
        end
      end
    end
        
    class TextItem < ::FFI::Struct
      include HashInit
      # include SG::AttrStruct
      layout :length, :uint8,
             :delta, :int8,
             :text, [ :char, 30 ]
      # calc_attr :length, lambda { self.text.size }
      # init_attr :delta, 0

      def []= attr, value
        if attr == :text && String === value
          self[:length] = value.size
          to_ptr.put_string(offset_of(:text), value)
        else
          super
        end
      end

      def text
        to_ptr.get_string(offset_of(:text), length)
      end
      
      def length
        self[:length]
      end
      
      def bytesize
        offset_of(:text) + length
      end
      
      def pack
        to_ptr.read_bytes(bytesize)
      end
      
      def self.read io
        n = io.read(1)
        nn = io.unpack('C')&.first
        self.new(FFI::MemoryPointer.from_string(n + io.read(nn - 1)))
      end
    end

    class PolyText8 < FFI::Struct
      include HashInit
      layout(
        :len, :int32,
        :detail, :int32,
        :drawable, :int32,
        :gc, :int32,
        :x, :int16,
        :y, :int16,
        :items, [ TextItem, 0 ])

      def pack
        to_ptr.read_bytes(self[:len])
      end
      
      def self.read io
        nr = io.read(4)
        raise EOFError unless nr
        n = nr.unpack('L')&.first
        self.new(FFI::MemoryPointer.from_string(nr + io.read(n - 4)))
      end
    end
    
    def name; "FFIMemory"; end

    def struct n
      data = TextItem.new(text: 'Hello')
      PolyText8.new(detail: n,
        len: 20 + data.bytesize,
        x: 100, y: 200, drawable: 20, gc: 123, items: [ data ])
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
