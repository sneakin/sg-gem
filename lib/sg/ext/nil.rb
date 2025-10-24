module SG::Ext
  refine ::NilClass do
    def try meth = nil, *args, **opts, &block
      warn("Deprecated since Ruby added &.", *caller_locations[0, 3])
      nil
    end

    # There is no truth.
    def true?; false; end
    # As falsey as it gets.
    def false?; true; end
    # As true as it gets.
    def blank?; true; end

    # Become false.
    def to_bool; false; end
  end
end
