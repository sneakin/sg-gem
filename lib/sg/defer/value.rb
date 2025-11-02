require 'sg/ext'
using SG::Ext

require_relative '../defer'
require_relative 'able'

module SG::Defer
  # A deferred value that requires calling {#wait} to get
  # the value from a production method.
  class Value
    include Able

    protected
    attr_reader :value

    public
    
    # Create a new value obtained by later calling the block argument.
    # @yield [self]
    # @yieldreturn [Object]
    def initialize &fn
      raise ArgumentError.new("No block given.") unless fn
      @producer = fn
    end

    # Wait for the actual value. The producer is called
    # on the first wait, which in expected to block until
    # available. Subsequent calls return or reraise the first value.
    # Without a block to {#initialize} this waits until {#ready?} goes true.
    # @return [Object]
    # @raise [RuntimeError]
    def wait
      raise @value if rejected?
      return @value if ready?

      v = @producer.call(self)
      v = v.wait while Waitable === v
      # could have waited on self
      ready?? (rejected?? raise(@value) : @value) : accept(v)
    rescue
      reject($!)
      raise
    end

    predicate :ready
    # Was the value an error?
    def rejected?; @ready == :rejected; end

    # Zero out the state and value.
    # @return [self]
    def reset!
      unready!
      @value = nil
      self
    end

    # Assign a value and set the state to ready. Assigning deferred
    # values return new deferred values further resolve the value
    # later.
    # @param v [Object]
    # @return [Object, Value]
    # @raise [AlreadyResolved]
    def accept v
      raise AlreadyResolved.new(self) if ready?
      ready!
      @value = v
    end

    # Assign the value and set the state to flag an error occurred.
    # @param v [StandardError, String]
    # @return [self]
    # @raise [AlreadyResolved]
    def reject v
      unless ready?
        ready!(:rejected)
        @value = v
      end
      self
    end

    # Used for arithmetic to promote values to deferred values.
    # @param other [Object]
    # @return [Array(Value, self)]
    def coerce other
      [ self.class.new { other }, self ]
    end
  end
end
