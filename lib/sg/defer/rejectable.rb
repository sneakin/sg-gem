module SG::Defer
  module Rejectable
    def reject v
      self
    end
  end
end
