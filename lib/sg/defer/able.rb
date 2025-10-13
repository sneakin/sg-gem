module SG::Defer
  # @abstract
  # The interface for reading the value of deferred values.
  module Waitable
    # @abstract
    # Call this to get the value by retrieving or generating data.
    def wait
      raise NotImplementedError
    end
  end

  # @abstract
  # The setter interface for a deferred value.
  module Acceptorable
    # @abstract
    # Accept a value os a happy value for later waits.
    def accept v
      v
    end
    # @abstract
    # Accept a value for the failure state to be raised by later waits.
    def reject v
      v
    end
  end
  
  # @abstract
  # An interface for objects that can wait for values
  # and then either accepts or rejects the new value for
  # later use.
  module Able
    def self.included base
      base.include Waitable
      base.include Acceptorable
    end
  end
end  
