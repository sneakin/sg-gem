module SG::Ext
  refine(Range) do
    def to_array_index
      if self.end < self.begin
        return self.end, (self.end - self.begin).abs + (self.exclude_end? ? 0 : 1)
      else
        return self.begin, self.size
      end
    end
  end
end
