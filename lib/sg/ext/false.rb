module SG::Ext
  refine ::FalseClass do
    def try meth = nil, *args, **opts, &block
      nil
    end

    def true?; false; end
    def false?; true; end
    def blank?; true; end

    def to_bool; false; end
  end
end
