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
      when /(.*)(fish|sheep)\Z/ then self
      when /(.*)(foot)\Z/ then $1 + 'feet'
      when /(.*)oose\Z/ then $1 + 'eese'
      when /(.*)[aoeui]y\Z/ then self + "s"
      when /(.*[^aoeui])y\Z/ then $1 + "ies"
      when /(ch|to|cho)\Z/ then self + 'es'
      when /(.*[^if])f\Z/ then $1 + 'ves'
      when /(.*[^f])fe\Z/ then $1 + 'ves'
      when /[^s]\Z/ then self + 's'
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
      gsub(/[[:upper:]]+/) { |m| m.capitalize }.
        gsub(/((?:\A|\s+|[-_]+)[[:alnum:]]+)/) { |m|
        m.gsub(/[-_]|\s+/, '').capitalize
      }
    end

    def decamelize delim: ' '
      # replace case transitions, spaces, and hyphens with ~delim~
      gsub(/[[:upper:]]+/) { |m| m.capitalize }.
        gsub(/(\s|[-_])+/, delim).
        gsub(/((?:\A|[[:lower:]])[[:upper:]])/) { |m| m[1] ? "%s%s%s" % [ m[0].downcase, delim, m[1].downcase ] : m.downcase }
    end

    def underscore
      # replace case transitions, spaces, and hyphens with underscores
      decamelize(delim: '_')
    end

    def hyphenate
      # replace case transitions, spaces, and hyphens with hyphens
      decamelize(delim: '-')
    end

    def to_bool
      !(self =~ /\A((no*)|(f(alse)?)|0*\Z)/i)
    end

    def split_at n
      [ self[0, n], self[n, size - n] ]
    end

    def strip_controls
      gsub(/[\x00-\x1F]+/, '')
    end
    
    def strip_escapes
      gsub(/(\e\[?[-0-9;]+[a-zA-Z])/, '')
    end

    def strip_display_only
      strip_escapes.strip_controls
    end

    def screen_size
      # size minus the escapes and control codes with double width chars counted twice
      #VisualWidth.measure(strip_display_only)
      strip_escapes.display_width
    end

    # todo use Terministry::Decoder
    # todo keep or remove escapes after the slice?
    def visual_slice len
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
  
    def to_proc
      lambda do |*args|
        self % case args
               in [ Array ] then args[0]
               else args
               end
      end
    end
  end
end
