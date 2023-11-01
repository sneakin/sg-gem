require 'sg/ext'
require 'sg/color'
require_relative 'constants'

module SG::Terminstry::Terminals
  class Base
    def fgbg f, b
      r = ''
      r += fg(f) if f
      r += bg(b) if b
      r
    end

    def fg c; ''; end
    def bg c; ''; end
    def normal; ''; end
    def bold; ''; end
    def underline; ''; end
    def italic; ''; end
  end
  
  # For a terminal lacking color support:
  class VT100 < Base
    def fg c
      "\e[%sm" % [ fg_gray(c.to(SG::Color::Gray).level) ]
    end

    def bg c
      "\e[%sm" % [ bg_gray(c.to(SG::Color::Gray).level) ]
    end

    def normal
      "\e[0m"
    end

    def bold; "\e[1m"; end
    def underline; "\e[4m"; end
    def italic; "\e[3m"; end

    protected
    
    def fg_gray level
      # blacken very low values, dim low levels, and
      # turn on bold for high levels
      # black, white+dim, white, white+bright,
      if level < 0.1
        "0;30"
      elsif level < 0.4
        "2;37"
      elsif level >= 0.75
        "1;37"
      else
        "0;37"
      end
    end

    def bg_gray level
      if level < 0.25
        "40"
      else
        "47"
      end
    end    
  end

  # For an old terminal with very basic 8 color
  # with dim and bright support.
  class XTerm < VT100
    def fg c
      hsl = c.to(SG::Color::HSL)
      return "\e[%sm" % [ fg_gray(hsl.luminosity) ] if hsl.saturation < 0.1

      # TODO move to SG::Color::VT100      
      # clamp the hue to the 6 colors
      c16 = hsl.to(SG::Color::VT100)
      "\e[%i;%im" % [ c16.attribute, 30 + c16.color_code ]
    end

    def bg c
      hsl = c.to(SG::Color::HSL)
      return "\e[%sm" % [ bg_gray(hsl.luminosity) ] if hsl.saturation < 0.1
      
      # clamp the hue to the 6 colors
      c16 = hsl.to(SG::Color::VT100)
      "\e[%im" % [ 40 + c16.color_code ]
    end
  end

  # For a terminal that support's XTerm's 256 color palette.
  class XTerm256 < XTerm
    def fg c
      fg_palette(color_index(c))
    end

    def bg c
      bg_palette(color_index(c))
    end

    protected
    
    def color_index c
      hsl = c.to(SG::Color::HSL)
      return gray_index(hsl.luminosity) if hsl.saturation < 0.1
      c = c.to(SG::Color::RGB)
      # The palette has a 6x6x6 RGB cube after the 16 standard colors.
      # All the RGB components are restricted to six values.
      16 + (c.red / 255.0 * 5).round * 36 +
        (c.green / 255.0 * 5).round * 6 +
        (c.blue / 255.0 * 5).round
    end
    
    def gray_index level
      # The default palette has 24 grays at its end.
      n = (level * 24).round
      n < 24 ?  232 + n : 15
    end
        
    def fg_palette index
      # 38 sets the foreground, 48 sets the background
      "\e[38;5;%im" % [ index ]
    end
    
    def bg_palette index
      # 38 sets the foreground, 48 sets the background
      "\e[48;5;%im" % [ index ]
    end
  end

  # For a terminal that support's XTerm's 24 bit color escape.
  # See: https://github.com/termstandard/colors
  class XTermTrue < XTerm
    def fg c
      c = c.to(SG::Color::RGB)
      "\e[38;2;%i;%i;%im" % c.to_a
    end
    
    def bg c
      c = c.to(SG::Color::RGB)
      "\e[48;2;%i;%i;%im" % c.to_a
    end
  end

  # For IOs that are not terminals and needs any escapes removed.
  class Dummy < Base
  end

  class HTML < Base
    def initialize
      @in_tag = 0
    end

    def fgbg f, b
      f = f.to(SG::Color::RGB)
      b = b.to(SG::Color::RGB)
      @in_tag += 1
      '<span style="color: #%s; background: #%s">' % [ f.to_hex_string, b.to_hex_string ]
    end

    def fg c
      c = c.to(SG::Color::RGB)
      @in_tag += 1
      '<span style="color: #%s">' % [ c.to_hex_string ]
    end

    def bg c
      c = c.to(SG::Color::RGB)
      @in_tag += 1
      '<span style="background: #%s">' % [ c.to_hex_string ]
    end

    def normal
      r = '</span>' * @in_tag
      @in_tag = 0
      r
    end

    def bold
      '<span style="font-weight: bold;">'
    end

    def underline
      '<span style="text-decoration: underline;">'
    end
    
    def italic
      '<span style="font-style: italic;">'
    end
  end

  def self.global
    @global ||= make_tty
  end
  
  def self.make_tty io = $stdout, opts = nil
    opts = {
      force_term: false,
      term: false,
      colorterm: false
    }.merge(opts || {})
    force_term = opts.fetch(:force_term) || ENV['FORCE_TERM']
    term = opts.fetch(:term) || ENV['TERM']
    cterm = opts.fetch(:colorterm) || ENV['COLORTERM']

    return Dummy.new unless io.tty? || force_term

    case term
    when 'html' then HTML.new
    when 'none' then Dummy.new
    when /^(xterm|eterm|linux|rxvt|tmux|screen)(?:-([^- ]+))?/ then
      colors = $2
      make_xterm(cterm) || make_xterm(colors) || XTerm.new
    else VT100.new
    end
  end

  protected
  
  def self.make_xterm colors
    case colors
    when 'truecolor' then XTermTrue.new
    when '256color' then XTerm256.new
    when /^gr[ae]y/ then VT100.new
    else nil
    end
  end
  
end
