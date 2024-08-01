require 'sg/terminstry/constants'
require 'sg/terminstry/decoder/vt100'
require 'sg/ext'

using SG::Ext

module SG::Terminstry
  class KeyReader
    class Key
      CONTROL = 1
      ALT = 2
      SHIFT = 4

      attr_reader :char, :modifiers
      
      def initialize c, modifiers = 0
        @char = c
        @modifiers = modifiers
      end

      def eql? other
        self.class === other &&
          char == other.char &&
          modifiers == other.modifiers
      end

      alias == eql?
    end

    class Mouse
      BUTTON1 = 1
      BUTTON2 = 2
      BUTTON3 = 3
      BUTTON4 = 4
      BUTTON5 = 6
      SHIFT = 1
      ALT = 2
      CONTROL = 4

      attr_reader :buttons, :x, :y, :modifiers

      def initialize buttons, x, y, modifiers = 0
        @buttons = buttons
        @x = x
        @y = y
        @modifiers = modifiers
      end
    end
      
    attr_reader :decoder
    
    def initialize decoder = Decoder::VT100.new(IO.console.each_char)
      @decoder = decoder
    end

    def each
      return to_enum(__method__) unless block_given?
      yield(decoder.read_key) while true
      self
    rescue EOFError, StopIteration
      self
    end
    
    def read max = nil
      en = each
      en = each.first(max) if max
      en
    end
  end
end
