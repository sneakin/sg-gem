module Runs
  class StdPack
    include Run
    
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
end
