module SG::Ext
  refine ::String do
    def blank?
      empty?
    end
    
    def pluralize
      case self
      when 'foot' then 'feet'
      when /(.*)[aoeui]y$/ then self + "s"
      when /(.*[^aoeui])y$/ then $1 + "ies"
      when /ch$/ then self + 'es'
      when /(.*[^f])f$/ then $1 + 'ves'
      when /(.*[^f])fe$/ then $1 + 'ves'
      when /[^s]$/ then self + 's'
      else self
      end
    end

    def titleize
      if size > 0
        self[0].upcase + self[1..-1]
      else
        self
      end
    end

    def camelize
      # capitalize and join the words
      gsub(/[[:upper:]]+/) { |m| m.capitalize }.
        gsub(/((?:^|\s+|[-_]+)[[:lower:]]+)/) { |m| m = m.gsub(/[-_]|\s/, ''); "%s%s" % [ m[0].upcase, m[1..-1].downcase ] }
    end

    def underscore
      # replace case transitions, spaces, and hyphens with underscores
      gsub(/[[:upper:]]+/) { |m| m.capitalize }.
        gsub(/(\s|-)+/, '_').
        gsub(/((?:^|[[:lower:]])[[:upper:]])/) { |m| m[1] ? "%s_%s" % [ m[0].downcase, m[1].downcase ] : m.downcase }
    end

    def to_bool
      !(self =~ /^((no*)|(f(alse)?)|0*$)/i)
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

    def visual_slice len
      if screen_size < len
        [ self, nil ]
      else
        part = ''
        width = 0
        in_escape = false
        each_char do |c|
          if width >= len
            break
          end
          if c == "\e"
            in_escape = true
          elsif in_escape && (Range.new('a'.ord, 'z'.ord).include?(c.ord) || Range.new('A'.ord, 'Z'.ord).include?(c.ord))
            in_escape = false
          elsif !in_escape
            width += Unicode::DisplayWidth.of(c)
          end
          part += c
        end
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
  end
end
