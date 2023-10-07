require 'x11rb'
require 'x11rb/xcb/packed/xproto'
require 'x11rb/xcb/bindata/xproto'
require 'benchmark'
require 'profile' if ENV['PROFILE']

phase = (ENV['PHASE'] || 0xFFFFFFFF).to_i
iterations = (ENV['ITERS'] || 1000).to_i

module Runs
  class Raw
    class Reader
      def read io
        io.read(44)
      end
    end
    
    def name; "Raw Data"; end
    
    def struct n
      "hello worldhello worldhello worldhello world"
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
  end

  class BinData
    def name; "BinData"; end
    
    def struct n
      data = X11RB::Protocol::BinData::PolyText8::TextItem.new(len: 5, text: 'Hello')
      X11RB::XCB::BinData::Xproto::PolyText8.new(detail: n, drawable: 20, gc: 123, x: 100, y: 200, items: data.to_binary_s)
    end

    def write pkt, io
      pkt.write(io)
    end
    
    def reader
      X11RB::XCB::BinData::Xproto::PolyText8
    end

    def read io
      reader.read(io)
    end
  end

  class Packed
    def name; "PackedStruct"; end

    def struct n
      data = X11RB::Protocol::Packed::PolyText8::TextItem.new(text: 'Hello').pack
      X11RB::XCB::Packed::Xproto::PolyText8.new(detail: n, len: X11RB.pad(16+data.bytesize)/4, x: 100, y: 200, drawable: 20, gc: 123, items: data)
    end

    def write pkt, io
      io.write(pkt.pack)
    end
    
    def reader
      X11RB::XCB::Packed::Xproto::PolyText8
    end

    def read io
      reader.read(io)
    end
  end

  def self.run bm, run, iterations, errs = true
    puts("\n= #{run.name}")
    inst = run.struct(-1)
    #puts(inst.inspect, inst.to_hash.inspect, inst.pack.inspect)
    
    io = StringIO.new
    bm.report("#{run.name} write")  do
      iterations.times do |n|
        pkt = run.struct(n)
        run.write(pkt, io)
      end
    end

    io.rewind

    bm.report("#{run.name} read") do
      iterations.times do |n|
        data = run.read(io)
        raise "Bad read #{n} #{data.inspect}" if errs && data.x != 100 && data.y != 200
      end
    end
  end
end

Benchmark.bm do |bm|
  if phase & 2 != 0
    Runs.run(bm, Runs::Packed.new, iterations)
  end

  if phase & 1 != 0
    Runs.run(bm, Runs::BinData.new, iterations)
  end

  if phase & 4 != 0
    Runs.run(bm, Runs::Raw.new, iterations, false)
  end
end
