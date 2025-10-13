require_relative 'futurable'

module SG::Defer
  # @abstract
  # An interface for objects that can wait for values
  # and then either accepts or rejects the new value for
  # later use.
  module Futurable
    def self.included base
      base.include Able
      base.include Rejectable
    end

    unless method_defined? :wait
      # @abstract
      # Call this to get the value by retrieving or generating data.
      def wait
        raise NotImplementedError
      end
    end

    # @abstract
    # Helps unpack [result, error] pairs for acceptance or rejection.
    def resolve ok, err
      err ? reject(err) : accept(ok)
    end

    # @abstract
    # Accept a value os a happy value for later waits.
    def resolve! v
      v
    end

    # @abstract
    # Accept a value for thebyailure state to be raised by later waits.
    def failed! v
      v
    end

    alias accept resolve!
    alias reject failed!

    # @abstract
    # Reset the state of this Futurable.
    def reset!
      self
    end
  end
end
