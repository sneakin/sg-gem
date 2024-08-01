require 'sg/terminstry/constants'
require 'sg/ext'

using SG::Ext

# todo finer details

module SG::Terminstry::Decoder
  class VT100
    class EscapeSeq
      attr_accessor :prefix, :params, :suffix

      def initialize suffix, params = nil, prefix: nil
        @prefix = prefix
        @params = (params || []).collect(&:to_s)
        @suffix = suffix
      end

      def to_s
        if mouse_event?
          "\e[M" + params.collect { |p| p.to_i + 32 }.pack('CCC')
        else
          "\e%s%s%s" % [ prefix, params.join(';'), suffix ]
        end
      end

      def char
        alt? && suffix
      end
        
      def control?
        alt? && suffix.codepoints[0] < 32
      end

      def alt?
        prefix.blank? && params.blank?
      end

      def shifted?
        alt? ? suffix.upper? : false
      end

      def mouse_event?
        prefix == '[M'
      end
      
      def eql? other
        self.class === other &&
          prefix == other.prefix &&
          params == other.params &&
          suffix == other.suffix
      end

      alias == eql?

      def hash
        params.collect(&:hash).reduce(prefix.hash ^ suffix.hash, &:^)
      end
    end

    class Key
      attr_reader :char
      
      def initialize c
        @char = c
      end

      def to_s
        char
      end
      
      def control?
        char.codepoints[0] < 32
      end

      def alt?
        false
      end

      def shifted?
        char.upper?
      end

      def mouse_event?
        false
      end
      
      def eql? other
        self.class === other &&
          char == other.char
      end

      alias == eql?

      def hash
        char.codepoints[0].hash
      end
    end

    class MouseEvent < EscapeSeq
      BUTTON1 = 0
      BUTTON2 = 1
      BUTTON3 = 2
      RELEASE = 3
      BUTTON_MASK = 3
      SHIFT = 4
      META = 8
      CONTROL = 16
      MOD_MASK = 0x1C
      EXTENDED = 64

      def buttons
        params[0].to_i
      end

      def x
        params[1].to_i
      end

      def y
        params[2].to_i
      end
      
      def shifted?
        buttons & SHIFT
      end

      def alt?
        buttons & META
      end
      
      def control?
        buttons & CONTROL
      end
    end
    
    attr_reader :src
    
    def initialize src = IO.console.each_char
      @src = Enumerator === src ? src : src.each_char
    end

    def read_param_immeds s
      while c = src.next
        s += c
        break if /[^- !"#$%&'()*+,.\/?`\\]/ =~ c
      end
      s
    end
    
    def read_params(prefix, c = src.next)
      params = []
      s = ''
      begin
        case c
        when ';' then
          params << s
          s = ''
        when /[- !"#$%&'()*+,.\/?`\\]/ then
          params << s unless s.empty?
          c = read_param_immeds(c)
          break
        when nil, /[^-0-9:;]/ then
          params << s unless s.empty?
          break
        else
          s += c
        end
      end while c = src.next

      EscapeSeq.new(c, params, prefix: prefix)
    end

    def read_until str
      s = ''
      while c = src.next
        s += c
        break if s.end_with?(str)
      end
      s
    end

    def read_mouse_event prefix = "[M"
      data = src.first(3)
      data = data.collect { |e| e.codepoints[0] - 32 }
      MouseEvent.new('', data, prefix: prefix)
    end
    
    def read_csi prefix = ''
      c = src.next
      case c
      when /[M]/ then
        read_mouse_event(prefix + c)
      when /[!<=>?]/ then
        read_params(prefix + c)
      else read_params(prefix, c)
      end
    end

    def read_until_st prefix, s = ''
      # until \e\\
      while c = src.next
        if c == "\e"
          c = src.next
          break if c == "\\"
          s += "\e" + c
        else
          s += c
        end
      end

      EscapeSeq.new("\e\\", [ s ], prefix: prefix)
    end

    Prefix8to7 = {
      "\x90" => "P", # DCS
      "\x9D" => "]", # OSC
      "\x9E" => "^", # PM
      "\x9F" => "_" # APC
    }
    
    def read_until_st_8bit prefix, s = ''
      # until \e\\
      while c = src.next
        if c == "\x9C"
          break
        else
          s += c
        end
      end

      EscapeSeq.new("\e\\", [ s ], prefix: Prefix8to7.fetch(prefix))
    end

    def read_and_one prefix
      c = src.next
      EscapeSeq.new(c, prefix: prefix)
    end
    
    def read_escape_seq
      c = src.next
      case c
      when '[' then read_csi(c)
      when /[X\]^_P]/ then read_until_st(c)
      when /[ON #%\(\)*+]/ then read_and_one(c)
      else EscapeSeq.new(c)
      end
    end
    
    def next
      c = src.next
      case c
      when "\e" then read_escape_seq
      when "\x9B" then read_csi('[')
      when "\x90", "\x9D", "\x9E", "\x9C" then read_until_st_8bit(c)        
      else Key.new(c)
      end
    end

    def each
      return to_enum(__method__) unless block_given?
      yield(self.next) while true
      self
    rescue EOFError, StopIteration
      self
    end
    
    Keys = {
      up: EscapeSeq.new('A', prefix: '['),
      down: EscapeSeq.new('B', prefix: '['),
      right: EscapeSeq.new('C', prefix: '['),
      left: EscapeSeq.new('D', prefix: '['),
      F1: EscapeSeq.new('P', prefix: 'O'),
      F2: EscapeSeq.new('Q', prefix: 'O'),
      F3: EscapeSeq.new('R', prefix: 'O'),
      F4: EscapeSeq.new('S', prefix: 'O'),
      F5: EscapeSeq.new('~', [ 15 ], prefix: '['),
      home: EscapeSeq.new('~', [ 1 ], prefix: '['),
      ins: EscapeSeq.new('~', [ 2 ], prefix: '['),
      del: EscapeSeq.new('~', [ 3 ], prefix: '['),
      :end => EscapeSeq.new('~', [ 4 ], prefix: '['),
      pgup: EscapeSeq.new('~', [ 5 ], prefix: '['),
      pgdn: EscapeSeq.new('~', [ 6 ], prefix: '['),
      sysreq: EscapeSeq.new('~', [ 19, 2 ], prefix: '['),
      brk: EscapeSeq.new('~', [ 21, 2 ], prefix: '['),
    }
    6.times { |n|
      Keys[("F%i" % [ 6 + n ]).to_sym] = EscapeSeq.new('~', [ 17 + n ], prefix: '[')
    }
    14.times { |n|
      Keys[("F%i" % [ 11 + n ]).to_sym] = EscapeSeq.new('~', [ 23 + n ], prefix: '[')
    }
    KeyNames = Keys.invert

    def key_name key
      KeyNames[key] || case key
                       when EscapeSeq then key.suffix if key.alt?
                       when Key then key.char
                       else nil
                       end
    end

    def read_key
      bk = nil
      begin
        key = self.next
        if key.mouse_event?
          # todo release
          bk = SG::Terminstry::KeyReader::Mouse.
            new(case key.buttons & (MouseEvent::BUTTON_MASK | MouseEvent::EXTENDED)
                when MouseEvent::BUTTON1 | MouseEvent::EXTENDED then SG::Terminstry::KeyReader::Mouse::BUTTON4
                when MouseEvent::BUTTON2 | MouseEvent::EXTENDED then SG::Terminstry::KeyReader::Mouse::BUTTON5
                when MouseEvent::BUTTON1 then SG::Terminstry::KeyReader::Mouse::BUTTON1
                when MouseEvent::BUTTON2 then SG::Terminstry::KeyReader::Mouse::BUTTON2
                when MouseEvent::BUTTON3 then SG::Terminstry::KeyReader::Mouse::BUTTON3
                else nil
                end,
                key.x, key.y,
                (key.control? ? SG::Terminstry::KeyReader::Mouse::CONTROL : 0) |
                (key.shifted? ? SG::Terminstry::KeyReader::Mouse::SHIFT : 0) |
                (key.alt? ? SG::Terminstry::KeyReader::Mouse::ALT : 0))
        else
          case key
          when EscapeSeq then kn = key_name(key)
          when Key then kn = key.char
          end

          if kn
            bk = SG::Terminstry::KeyReader::Key.
              new(kn,
                  (key.control? ? SG::Terminstry::KeyReader::Key::CONTROL : 0) |
                  (key.shifted? ? SG::Terminstry::KeyReader::Key::SHIFT : 0) |
                  (key.alt? ? SG::Terminstry::KeyReader::Key::ALT : 0))
          end
        end
      end until bk

      bk
    end
  end
end
