module SG::Ext
  refine ::IO do
    def read_until chars, chomp: true
      r = ''
      while (c = getc) && !chars.include?(c)
        r << c
      end
      r << c unless chomp
      r
    rescue EOFError
      r
    end
  end
end
