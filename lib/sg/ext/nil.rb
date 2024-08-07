module SG::Ext
  refine ::NilClass do
    def try meth = nil, *args, **opts, &block
      warn("Deprecated since Ruby added &.")
      nil
    end

    def true?; false; end
    def false?; true; end
    def blank?; true; end

    def to_bool; false; end
  end
end
