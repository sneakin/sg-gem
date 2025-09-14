require 'sg/packed_struct'
require 'bindata'
require 'ffi'
require 'benchmark'
require 'profile' if ENV['PROFILE']

phase = (ENV['PHASE'] || 0xFFFFFFFF).to_i
iterations, outer_iterations = (ENV.fetch('ITERS', '1000,3')).split(/(\s|,)/).collect(&:to_i)
outer_iterations = 1 if !outer_iterations || outer_iterations <= 0

module Runs
  class Raw
    class Reader
      def read io
        io.read(44)
      end
    end
    
    def name; "Raw Data"; end
    
    def struct n
      [ "\e\u0000\u0000\u0000", n, "\u0014\u0000\u0000\u0000{\u0000\u0000\u0000d\u0000\xC8\u0000\u0005\u0000Hello" ].pack('a*La*')
    end

    def write pkt, io
      io.write(pkt)
    end
    
    def reader
      Reader.new
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

  class BinData
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

  class Packed
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

  class FFIMemory
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

  def self.run bm, run, iterations, errs = true
    inst = run.struct(-1)
    io = StringIO.new

    bm.report("#{run.name} write\t")  do
      iterations.times do |n|
        pkt = run.struct(n)
        run.write(pkt, io)
      end
    end

    io.rewind

    bm.report("#{run.name} read\t") do
      iterations.times do |n|
        data = run.read(io)
        #puts data.inspect
        raise "Bad read #{n} #{data.inspect}" if errs && Array === data && data[0].text != 'Hello' && data[0].length != 5
      rescue SG::PackedStruct::NoDataError
        raise "EOF #{n} #{io.pos}"
      end
    end
  end
end

if $0 == __FILE__
  runs = []
  ARGV.each { runs << Runs.const_get(_1).new }
  if runs.empty?
    runs = [ Runs::BinData.new, Runs::Packed.new, Runs::FFIMemory.new, Runs::Raw.new ]
  end
  a = b = nil
  runs.combination(2) { raise "Mismatch: #{_1.name} #{_2.name}\n#{a.inspect}\n#{b.inspect}" if (a = _1.write_one) != (b = _2.write_one) }
  outer_iterations.times do
    Benchmark.bm do |bm|
      runs.each { Runs.run(bm, _1, iterations, Runs::Raw === _1) }
    end
  end
end