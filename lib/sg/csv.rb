require 'sg/ext'
using SG::Ext

module SG
  class CSV
    attr_reader :headers, :entries
    attr_reader :separator, :field_regex
    
    def initialize separator: nil
      @headers = nil
      @entries = []
      @separator = separator || ','
      # (Single quoted | double quoted | not commas) comment?
      @field_regex = /([']([^']+)[']|["]([^"]+)["]|([^#{@separator}#]+))(?:#.*)?/
    end

    def each &cb
      @entries.each(&cb)
    end

    def read io, keep: true, headings: true, &cb
      if headings
        @headers = split_line(io.readline)
        cb.call(*@headers) if cb && keep && headings == :keep
      end
      while line = io.readline
        next if line =~ /^#/
        fields = split_line(line)
        @entries << fields if keep
        cb.call(*fields) if cb
      end
      self
    rescue EOFError
      self
    end
    
    def split_line line
      # todo unescape quoted values
      line.rstrip.scan(@field_regex).
        collect { _1[2] || _1[0] }
    end
    
    def self.read(...)
      new.read(...)
    end
  end
end
