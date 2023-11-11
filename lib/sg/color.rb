require 'sg/ext'
require 'sg/converter'

using SG::Ext

module SG
  module Color
    class Base
      include SG::Convertible

      def clamp; self; end
      def clamp!; self; end
    end

    class Gray < Base
      attr_accessor :level
      
      def initialize level
        @level = level
      end

      def clone
        self.class.new(level)
      end
      
      def to_s
        "Gray(%f)" % [ level ]
      end

      def invert
        Gray.new(1.0 - level)
      end

      def clamp!
        @level = @level.clamp(0, 1)
        self
      end

      def clamp
        clone.clamp!
      end
    end

    class VT100 < Base
      ATTR_NONE = 0
      ATTR_DIM = 2
      ATTR_BRIGHT = 1

      Primary = Struct.new(:name, :code, :attr, :rgb, :inverted)

      Colors = {
        # color code, attributes, rgb, inversion
        black: [ 0, 0, 0x0, :white ],
        gray: [ 7, 0, 0x808080, :gray ],
        red: [ 1, 0, 0x800000, :cyan ],
        yellow: [ 3, 0, 0x808000, :blue ],
        green: [ 2, 0, 0x008000, :magenta ],
        cyan: [ 6, 0, 0x008080, :red ],
        blue: [ 4, 0, 0x000080, :yellow ],
        magenta: [ 5, 0, 0x800080, :green ],
        # dims
        darkgray: [ 7, 2, 0x404040, :gray ],
        darkred: [ 1, 2, 0x400000, :brightcyan ],
        darkyellow: [ 3, 2, 0x404000, :brightblue ],
        darkgreen: [ 2, 2, 0x004000, :brightmagenta ],
        darkcyan: [ 6, 2, 0x004040, :brightred ],
        darkblue: [ 4, 2, 0x000040, :brightyellow ],
        darkmagenta: [ 5, 2, 0x400040, :brightgreen ],
        # brights
        white: [ 7, 1, 0xFFFFFF, :black ],
        brightred: [ 1, 1, 0xFF0000, :darkcyan ],
        brightyellow: [ 3, 1, 0xFFFF00, :darkblue ],
        brightgreen: [ 2, 1, 0x00FF00, :darkmagenta ],
        brightcyan: [ 6, 1, 0x00FFFF, :darkred ],
        brightblue: [ 4, 1, 0x0000FF, :darkyellow ],
        brightmagenta: [ 5, 1, 0xFF00FF, :darkgreen ]      
      }.collect do |name, info|
        [ name, Primary.new(name, *info) ]
      end.to_h

      ColorCodes = Colors.reduce({}) do |h, (name, color)|
        h[name.to_s] = color.code
        h
      end
      
      def initialize i, attr = nil
        case i
        when Integer then
          attr = case i
                 when (0x20..0x30) then ATTR_DIM
                 when (0x10..0x20) then ATTR_BRIGHT
                 else attr || ATTR_NONE
                 end
          @key, @color = Colors.
                           find_all { |k,v| v.code == (i & 7) }.
                           branch((i&7) == 0,
                                  lambda { |c| c.first },
                                  lambda { |c| c.find { |k,v| v.attr == attr } })
        when String then
          attr = case i
                 when /^bright/ then ATTR_BRIGHT
                 when /^dark/ then ATTR_DIM
                 else attr
                 end
          initialize(ColorCodes[i], attr)
        when Symbol then
          initialize(i.to_s, attr)
        else raise TypeError.new("Invalid color: #{i.inspect}")
        end
        raise ArgumentError.new("Invalid color: #{i.inspect} #{attr.inspect}") if @color == nil
      end

      def name
        @color.name
      end
      
      def color_code
        @color.code
      end

      def attribute
        @color.attr
      end
      
      def raw_rgb
        @color.rgb
      end
      
      def to_s
        "VT100(:%s)" % [ @key ]
      end

      def invert
        self.class.new(@color.inverted)
      end

      def + other
        (to(RGB) + other).to(self.class)
      end
    end

    class HSL < Base
      def initialize h, s, l
        @c = [ h, s, l ]
      end

      def clone
        self.class.new(*@c)
      end
      
      def hue; @c[0]; end
      def saturation; @c[1]; end
      def luminosity; @c[2]; end

      def to_s
        "HSL(%f, %f, %f)" % @c
      end

      def to_a; @c; end

      def invert
        self.class.new((hue + 180) % 360, saturation, luminosity)
      end

      def + other
        if other.kind_of?(self.class)
          h = [ (other.hue - hue).abs,
                (360 + other.hue - hue).abs ].min
          h = hue + h / 2
          self.class.new(h,
                         [ saturation, other.saturation ].average,
                         [ luminosity, other.luminosity ].average)
        else
          a, b = other.coerce(self)
          b + a
        end
        #other = SG::Converter.convert(other, self.class)
        #self.class.new(*@c.zip(other.to_a).collect(&:sum))
      end

      #def - other
      #  other = SG::Converter.convert(other, self.class)
      #  self.class.new(*@c.zip(other.to_a).collect { |(a,b)| a - b })
      #end

      def clamp!
        @c[0] = @c[0] % 360
        @c[1] = @c[1].clamp(0, 1)
        @c[2] = @c[2].clamp(0, 1)
        self
      end

      def clamp
        clone.clamp!
      end
    end

    class RGB < Base
      def initialize r, g = nil, b = nil
        if g == nil && b == nil
          case r
          when Integer then
            @c = [ (r >> 16) & 0xFF, (r >> 8) & 0xFF, r & 0xFF ]
          when /#?(\h\h)(\h\h)(\h\h)/ then
            @c = [ $1, $2, $3 ].collect { |n| n.to_i(16) }
          when /#?(\h)(\h)(\h)/ then
            @c = [ $1, $2, $3 ].
                   collect { |n| n.to_i(16) }.
                   collect { |n| n * 16 + n }
          else raise ArgumentError
          end
        else
          @c = [ r, g, b ]
        end
      end

      def red; @c[0]; end
      def green; @c[1]; end
      def blue; @c[2]; end

      def each &block
        @c.each(&block)
      end
      
      def to_hex_string
        "%.2x%.2x%.2x" % @c
      end

      def to_s
        "RGB(%i,%i,%i)" % @c
      end

      def to_a; @c; end
      def to_i; @c.reduce(0) { |a, c| (a << 8) | (c.round.to_i & 0xFF) }; end

      def invert
        self.class.new(*@c.collect { |n| 255 - n })
      end

      def -@
        invert
      end
      
      def + other
        other = SG::Converter.convert(other, self.class)
        self.class.new(*@c.zip(other.to_a).collect(&:sum))
      end

      def - other
        other = SG::Converter.convert(other, self.class)
        self.class.new(*@c.zip(other.to_a).collect { |(a,b)| a - b })
      end

      def * other
        case other
        when Numeric then self.class.new(*@c.collect { |a| a * other })
        else
          other = SG::Converter.convert(other, self.class)
          self.class.new(*@c.zip(other.to_a).collect { |(a,b)| a * b / 256.0 })
        end
      end

      def / other
        case other
        when Numeric then self.class.new(*@c.collect { |a| a / other })
        else
          other = SG::Converter.convert(other, self.class)
          self.class.new(*@c.zip(other.to_a).collect { |(a,b)| a / b })
        end
      end
      
      def clamp!
        @c = @c.collect { |n| n.clamp(0, 255) }
        self
      end

      def clamp
        clone.clamp!
      end

      def clone
        self.class.new(*@c)
      end
    end

    # String to color conversion
    
    def self.from_string s
      case s
      when /^hsl\((.*)\)/i then
        HSL.new(*$1.split(',').collect(&:to_f))
      when /^rgb\((\d+)\s*,\s*(\d+)\s*,\s*(\d+)\)/i then
        RGB.new($1.to_i, $2.to_i, $3.to_i)
      when /^rgb\(0x(\h+)\s*,\s*0x(\h+)\s*,\s*0x(\h+)\)/i then
        RGB.new($1.to_i(16), $2.to_i(16), $3.to_i(16))
      when /^#(\h)(\h)(\h)$/ then
        c = [ $1, $2, $3 ].
              collect { |x| x.to_i(16) }.
              collect { |x| x * 16 + x }
        RGB.new(*c)
      when /^#(\h\h)(\h\h)(\h\h)$/ then
        RGB.new($1.to_i(16), $2.to_i(16), $3.to_i(16))
      when /^gr[ae]y:(.+)/ then Gray.new($1.to_f)
      when /^(?:vt(?:100)?:)?(\h+)$/ then VT100.new($1.to_i(16))
      when /^(?:vt(?:100)?:)?(.+)$/ then VT100.new($1)
      else VT100.new(s)
      end
    end

    [ HSL, RGB, Gray, VT100 ].each do |klass|
      SG::Converter.register(String, klass) do |s|
        Color.from_string(s).to(klass)
      end
    end
    
    # Gray converters
    
    SG::Converter.register(Gray, RGB) do |g|
      l = g.level * 255
      RGB.new(l, l, l)
    end

    SG::Converter.register(Gray, HSL) do |g|
      HSL.new(0, 0, g.level)
    end

    # VT100 Converters

    SG::Converter.register(VT100, RGB) do |vt|
      RGB.new(vt.raw_rgb)
    end

    # SG::Converter.register(VT100, HSL) do |vt|    
    #   vt.to(RGB).to(HSL)
    # end

    # SG::Converter.register(VT100, Gray) do |vt|
    #   vt.to(RGB).to(Gray)
    # end
    
    # HSL Converters
    
    SG::Converter.register(HSL, RGB) do |hsl|
      # See: https://www.had2know.org/technology/hsl-rgb-color-converter.html
      d = hsl.saturation * (1 - (2 * hsl.luminosity - 1).abs)
      m = (hsl.luminosity - 0.5 * d)
      x = d * (1 - ((hsl.hue / 60.0) % 2 - 1).abs)
      rgb = case hsl.hue
            when 0...60 then [ d, x, 0 ]
            when 60...120 then [ x, d, 0 ]
            when 120...180 then [ 0, d, x ]
            when 180...240 then [ 0, x, d ]
            when 240...300 then [ x, 0, d ]
            else [ d, 0, x ]
            end
      rgb = rgb.collect { |c| 255 * (c + m) }
      RGB.new(*rgb)
    end

    # SG::Converter.register(HSL, Gray) do |hsl|      
    #   hsl.to(RGB).to(Gray)
    # end

    SG::Converter.register(HSL, VT100) do |hsl|      
      # turn on bold when luminosity is above 0.5,
      attr = VT100::ATTR_NONE
      attr = if hsl.luminosity >= 0.4
               VT100::ATTR_BRIGHT
             elsif hsl.luminosity < 0.2
               VT100::ATTR_DIM
             end

      # turn to black near zero, and turn to white when satuarated
      n = if hsl.luminosity >= 0.99
            :white
          elsif hsl.luminosity <= 0.0
            :black
          else
            # clamp the hue to the 6 colors
            case hsl.hue.to_i
            when 0...30 then :red
            when 30...90 then :yellow
            when 90...160 then :green
            when 160...210 then :cyan
            when 210...270 then :blue
            when 270...330 then :magenta
            else :red
            end
          end

      VT100.new(n, attr)
    end

    # RGB Converters

    SG::Converter.register(Integer, RGB) do |i|
      RGB.new(i)
    end
    
    SG::Converter.register(RGB, Integer) do |rgb|
      rgb.to_i
    end
    
    SG::Converter.register(Array, RGB) do |arr|
      RGB.new(*arr)
    end
    
    SG::Converter.register(RGB, Array) do |rgb|
      rgb.to_a
    end
    
    SG::Converter.register(RGB, HSL) do |rgb, maxed = false|
      r, g, b = rgb.to_a.collect { |c| c.to_f / 255.0 }
      min, max = [ r, g, b ].minmax
      h = 0.0
      s = 0.0
      l = (max + min) / 2.0
      if max != min
        d = max - min
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
        case max
        when r then h = (g - b) / d + (g < b ? 6 : 0)
        when g then h = (b - r) / d + 2
        when b then h = (r - g) / d + 4
        end
        # h = h / 6.0
      end
      # in the range of 0..1. Hue can be *360 (when /6).
      # max for l due to rgb(255,0,0) being half bright
      HSL.new(h * 60, s, maxed ? max : l)
    end  

    SG::Converter.register(RGB, Gray) do |rgb|
      Gray.new(rgb.to_a.average / 255.0)
    end

    # SG::Converter.register(RGB, VT100) do |rgb|
    #   rgb.to(HSL).to(VT100)
    # end

    SG::Converter.register(VT100, Integer) do |v|
      v.color_code
    end

    SG::Converter.register(Integer, VT100, 2) do |v|
      $stderr.puts v.inspect, v.class
      VT100.new(v)
    end

    SG::Converter.register(VT100, String) do |v|
      v.name.to_s
    end
  end
end
