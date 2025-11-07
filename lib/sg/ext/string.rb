require 'unicode/display_width/string_ext'
require 'unicode/emoji'

module SG::Ext
  refine ::String do
    def blank?
      empty? || !!(/\A\s+\Z/ =~ self)
    end

    %w{ space upper lower
        alnum alpha digit xdigit
        cntrl graph print
        punct word ascii
    }.each do |cc|
      class_eval <<-EOT
        def #{cc}?
          !!(self =~ /\\A[[:#{cc}:]]+\\Z/)
        end
EOT
    end

    def pluralize
      case self
      when /(.*)(fish|sheep|feet|eese)\Z/ then self
      when /(.*)(foot)\Z/ then $1 + 'feet'
      when /(.*choose)\Z/ then $1 + 's'
      when /(.*)oose\Z/ then $1 + 'eese'
      when /(.*)[aoeui]y\Z/ then self + "s"
      when /(.*[^aoeui])y\Z/ then $1 + "ies"
      when /(sh|ch|to|cho)\Z/ then self + 'es'
      when /(.*[^if])f\Z/ then $1 + 'ves'
      when /(.*[^f])fe\Z/ then $1 + 'ves'
      when /ss\Z/ then self + 'es'
      when /[^s]\Z/ then self + 's'
      else self
      end
    end

    def singularize
      case self
      when /(.*)(fish|sheep|cheese)\Z/ then self
      when /(.*)(feet)\Z/ then $1 + 'foot'
      when /(.*)eese\Z/ then $1 + 'oose'
      when /(.*[aoeui]y)s\Z/ then $1
      when /(.*[^aoeui])ies\Z/ then $1 + "y"
      when /(.*[aoeui]se)s\Z/ then $1
      when /(.*)fives\Z/ then $1 + 'five'
      when /(.*[^if])ves\Z/ then $1 + 'f'
      when /(.*[^f])ves\Z/ then $1 + 'fe'
      when /(.*ss)es\Z/ then $1
      when /(.*(sh|ch|o))es\Z/ then $1
      when /(.*[^s])s\Z/ then $1
      else self
      end
    end
    
    def titleize
      # upcase post-space, underscore, hypens, and slashes
      gsub(/(\A|\s+|[-_\\\/]+)[[:lower:]]/) { |m| m.upcase }
    end

    # fixme 'hello world' -> 'HelloWorld', 'Hello World' -> 'HelloWorld'
    def camelize
      # capitalize and join the words
      # scan words, spaces, and delimeters
      scan(/(?:[[:alnum:]]+|(?:\s|[-_\/\\])+)/).
        reject { |p| p.blank? || p =~ /\A[-_]+\Z/ }.
        collect { |p|
          # all uppercase words get downcased
          # while mixed case words only upcase the first letter
          if p =~ /\A(?:[[:upper:]]|[[:digit:]])+\Z/
            p.capitalize
          else
            p.titleize
          end
        }.join.gsub(/(.?)([-_\/\\]+)(.?)/) {
          if $1.space?
            # strip spaces around delimeters
            $2 + ($3.space? ? '' : $3)
          else
            # no spaces so replace delimeters
            $1 + '::' + $3
          end
        }
    end

    def decamelize delim: ' '
      # replace case transitions, spaces, and hyphens with ~delim~
      # while replacing common delimeters with ~delim~.
      rep = '\1%s\2' % [ delim ]
      gsub(/HSLLuminosity/i, 'hsl luminosity').
        gsub(/([[:lower:]])([[:upper:]])/, rep).
        gsub(/([[:upper:]]{2,})([[:lower:]])/, rep).
        gsub(/(\s+|[-_])/, delim).
        downcase
    end

    def underscore
      # replace case transitions, spaces, and hyphens with underscores
      decamelize(delim: '_')
    end

    def demodularize
      underscore.gsub('::', '/')
    end

    def modularize
      camelize.gsub('/', '::')
    end

    def hyphenate
      # replace case transitions, spaces, and hyphens with hyphens
      decamelize(delim: '-')
    end
  
    def to_proc
      lambda do |*args|
        self % case args
               in [ Array ] then args[0]
               else args
               end
      end
    end

    def to_bool
      !(self =~ /\A((no*)|(f(alse)?)|0*\Z)/i)
    end

    def split_at n
      n = index(n) unless Integer === n
      n = size + n if n < 0
      [ self[0, n], self[n, size - n] ]
    end

    # Strips all bytes less than 32 aka " ".
    def strip_controls
      gsub(/[\x00-\x1F]+/, '')
    end
    
    # Strips substrings like "\e", "\eX", "\e(A", "\e[-12;34X".
    def strip_escapes
      gsub(/\e(\Z|[\[\]]*[-0-9;]*[[:alnum:]]|[()][[:alnum:]]|\w)/, '')
    end

    # Strips control and escaped characters.
    def strip_display_only
      strip_escapes.strip_controls
    end

    # #size minus the escape sequences, control codes,
    # and double width chars counted twice.
    def screen_size
      #VisualWidth.measure(strip_display_only)
      strip_display_only.display_width
    end

    # Slices by #screen_size factoring in non-displayed sequences.
    def visual_slice len
      # todo use Terministry::Decoder
      # todo keep or remove escapes after the slice?
      if screen_size == size && screen_size <= len
        [ self, nil ]
      else
        part = ''
        width = 0
        saw_escape = false
        in_escape = false
        each_char do |c|
          if width >= len
            break
          end
          if c == "\e"
            in_escape = true
          elsif in_escape && c.alpha?
            in_escape = false
            if c == 'm'
              saw_escape = !(part =~ /[\[;]0+\Z/)
            end
          elsif !in_escape
            width += Unicode::DisplayWidth.of(c)
          end
          part += c
        end
        part += "\e[0m" if saw_escape
        return [ part, self[part.size..-1] ]
      end
    end
    
    def each_visual_slice n, &cb
      return to_enum(__method__, n) unless cb

      if screen_size < n
        cb.call(self)
      else
        rest = self
        begin
          sl, rest = rest.visual_slice(n)
          cb.call(sl)
        end while(rest && !rest.empty?)
      end

      self
    end

    def truncate len
      visual_slice(len).first
    end

    def cycled n
      return '' if n <= 0 || empty?
      return self if n == size
      return self[0, n.ceil] if n < size
      (self * (n / size.to_f).ceil)[0, n.ceil] 
    end
    
    def cycle_visually n
      return '' if n <= 0 || empty?
      return truncate(n) if n <= screen_size
      (self * (n / screen_size.to_f).ceil).truncate(n)
    end
    
    def center_visually len, pad = nil
      pad ||= ' '
      padding = (len - screen_size)
      padding <= 0 ? self : pad.cycled(size + padding).
        tap { |s| s[padding / 2, size] = self }
    end

    def ljust_visually len, pad = nil
      pad ||= ' '
      padding = (len - screen_size)
      padding <= 0 ? self : pad.cycled(size + padding).
        tap { |s| s[0, size] = self }
    end
    
    def rjust_visually len, pad = nil
      pad ||= ' '
      padding = (len - screen_size)
      padding <= 0 ? self : pad.cycled(size + padding).
        tap { |s| s[-size, size] = self }
    end
  end

  EscapableCharMap = {
    "\\" => "\\",
    '#' => '#',
    '0' => "\x00",
    'b' => "\b",
    'e' => "\e",
    'f' => "\f",
    'n' => "\n",
    'r' => "\r",
    't' => "\t",
    'v' => "\v",
  }
  EscapableChars = EscapableCharMap.keys.join.gsub("\\", "\\\\\\\\")

  refine String do
    def unescape quotes: "'\""
      gsub(/\\([#{quotes}])/, '\1').
        gsub(/\\u([0-9a-f]{4})/i) { [ _1[2..-1].to_i(16) ].pack('U') }.
        gsub(/\\x([0-9a-f]{2})/i) { [ _1[2..-1].to_i(16) ].pack('C') }.
        gsub(/\\([#{EscapableChars}])/) { EscapableCharMap[_1[1]] || _1 }
    end    
  end
end
