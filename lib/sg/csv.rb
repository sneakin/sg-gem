require 'sg/ext'
using SG::Ext

module SG
  class CSV
    class UnterminanedQuoteError < RuntimeError
      def initialize line, num = nil
        super("Unterminaned quotation%s: %s" %
              [ num ? " on line #{num}" : '',
                line
              ])
      end
    end

    # The values from the first line.
    attr_reader :headers
    # An Array of the entries
    attr_reader :entries
    # String of characters used to delineate quoted values.
    attr_reader :quotes
    # The string that starts comments.
    attr_reader :comments
    # The character separating records.
    attr_reader :record_separator
    # The character that separates fields.
    attr_reader :field_separator
    # The full regex used for scanning.
    attr_reader :field_regex

    predicate :strip, read_only: true

    # @param field_separator [String] Characters separating fields.
    # @param record_separator [String] Character separating records.
    # @param quotes [String] Characters that delineate quoted values.
    # @param comments [String] String used to start comments.
    # @param strip [Boolean] To strip values?
    def initialize field_separator: nil, record_separator: nil, quotes: nil, comments: nil, strip: false
      @headers = nil
      @entries = []
      @strip = strip
      @record_separator = record_separator || "\n"
      @field_separator = field_separator || ','
      @comments = comments || '#'
      @quotes = quotes || "'\""
      # (Single quoted | double quoted | not commas) comment?
      qr = @quotes.each_char.
        collect { "[#{_1}]((?:\\\\#{_1}|[^#{_1}])*)[#{_1}]" }.join('|')
      @field_regex = /(#{qr}|([^#{@field_separator}]+))/m
    end

    delegate :size, :each, to: :entries

    # @param io [IO, String] The input.
    # @param keep [Boolean] Whether to add tte entries.
    # @param headings [Boolean, Symbol] Truthy to treat the first line as the headings, :keep will also yield them.
    # @param as_hash [Boolean] Set to field hashes.
    # @yield [fields]
    # @yieldparam fields [Array, Hash]
    # @return [self]
    def read io, keep: true, headings: true, as_hash: false, &cb
      io = StringIO.new(io) if String === io
      if headings
        @headers = readline(io)
        cb.call(*@headers) if cb && keep && headings == :keep
      end
      while fields = readline(io)
        @entries << fields if keep
        if cb
          if as_hash
            cb.call(Hash[headers.zip(fields)])
          else
            cb.call(*fields)
          end
        end
      end
      self
    end

    def self.read(...)
      new.read(...)
    end

    def readline io
      begin
        line = io.readline(record_separator)
        line, *comment = line.split(comments)
        # $stderr.puts(__method__, line, comment.inspect)
      end while line.blank?
      fields = split_line(line, line_num: io.lineno)
    rescue EOFError
      nil
    end
    
    def split_line line, line_num: nil
      line.chomp(record_separator).scan(@field_regex).
        # tap { $stderr.puts(__method__, _1.inspect) }.
        tap {
          _1.collect(&:first).select(&/\A[#{quotes}]/).
          all?(&/\A([#{quotes}]).*\1\Z/m) || raise(UnterminanedQuoteError.new(line, line_num))
        }.
        collect {
          (_1[2] && unescape(_1[2])) ||
          (_1[1] && unescape(_1[1])) ||
          _1[0]
        }.
        skip_unless(strip?).collect(&:strip)
        # tap { puts("After", _1.inspect) }
    end
    
    Specials = {
      "\\" => "\\",
      '0' => "\x00",
      'b' => "\b",
      'e' => "\e",
      'f' => "\f",
      'n' => "\n",
      'r' => "\r",
      't' => "\t",
      'v' => "\v",
    }
    SpecialChars = Specials.keys.join.gsub("\\", "\\\\\\\\")
    
    def unescape str
      str.gsub(/\\([#{quotes}])/, '\1').
        gsub(/\\([#{SpecialChars}])/) { Specials[_1[1]] || _1 }
    end
  end
end
