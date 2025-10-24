module SG::Ext
  refine ::FalseClass do
    def try meth = nil, *args, **opts, &block
      nil
    end

    # Not true.
    def true?; false; end
    # As false as it gets.
    def false?; true; end
    # Blank too.
    def blank?; true; end

    # Make sure to be Boolean.
    def to_bool; false; end
  end
end
