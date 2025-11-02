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
      @producer = fn || lambda { |_| wait_ready }
      @mut = Mutex.new
      @cv = ConditionVariable.new
    end

    # Wait for the actual value. The producer is called
    # on the first wait, which in expected to block until
    # available. Subsequent calls return or reraise the first value.
    # Without a block to {#initialize} this waits until {#ready?} goes true.
    # @return [Object]
    # @raise [RuntimeError]
    def wait
      @mut.synchronize do
        raise @value if rejected?
        return @value if ready?
      end
      begin
        v = @producer.call(self)
        v = v.wait while Waitable === v
        # could have waited on self
        ready?? (rejected?? raise(@value) : @value) : accept(v)
      rescue
        reject($!)
        raise
      end
    end

    predicate :ready
    # Was the value an error?
    def rejected?; @ready == :rejected; end

    # Zero out the state and value.
    # @return [self]
    def reset!
      @mut.synchronize do
        unready!
        @value = nil
      end
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
      @mut.synchronize do
        ready!
        @value = v
        @cv.signal
        @value
      end
    end

    # todo no raise on reject. raise only on woit
    
    # Assign the value and set the state to flag an error occurred.
    # @param v [StandardError, String]
    # @return [Object]
    # @raise [AlreadyResolved]
    def reject v
      unless ready?
        @mut.synchronize do
          ready!(:rejected)
          @value = v
          @cv.signal
        end
      end
      self
    end

    # Used for arithmetic to promote values to deferred values.
    # @param other [Object]
    # @return [Array(Value, self)]
    def coerce other
      [ self.class.new { other }, self ]
    end

    def wait_ready secs = nil
      @mut.synchronize do
        @cv.wait(@mut, secs)
      end
      self
    end
  end
end
