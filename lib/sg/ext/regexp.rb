module SG::Ext
  refine Regexp do
    def to_proc
      lambda { _1 =~ self }
    end
  end
end
