require 'sg/ext'
using SG::Ext

require_relative 'able'

module SG::Defer
  # A deferred value that requires calling #wait to get
  # the value from a production method.
  class Value
    include Able

    # Create a new value obtained by later calling the block argument.
    # @yield [void]
    # @yieldreturn [Object]
    def initialize &fn
      @producer = fn
      @mut = Mutex.new
    end

    # Get the actual value or raise an error. The producer is called
    # on the first wait, which in expected to block until
    # available. Subsequent calls return or reraise the first value.
    # @return [Object]
    # @raise [RuntimeError]
    def wait
      @mut.synchronize do
        raise @value if rejected?
        return @value if ready?
      end
      begin
        return nil unless @producer
        v = @producer.call
        v = v.wait while Waitable === v
        # could have waited on self
        ready?? @value : accept(v)
      rescue
        reject($!) unless ready?
        raise
      end
    end

    # Has a value been obtained?
    def ready?; !!@ready; end
    # Was the value an error?
    def rejected?; @ready == :rejected; end

    # Zero out the state and value.
    # @return [self]
    def reset!
      @mut.synchronize do
        @ready = nil
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
      
      if Waitable === v
        self.class.new do
          accept(v.wait)
        rescue
          reject($!)
          raise
        end
      else
        @mut.synchronize do
          @ready = true
          @value = v
          @value
        end
      end
    end

    # Assign te value and set the state to flag an error occurred.
    # @param v [StandardError, String]
    # @return [Object]
    # @raise [AlreadyResolved]
    def reject v
      raise AlreadyResolved.new(self) if ready?
      @mut.synchronize do
        @ready = :rejected
        @value = v
      end
      @value
    end

    # Used for arithmetic to promote values to deferred values.
    # @param other [Object]
    # @return [Array(Value, self)]
    def coerce other
      [ self.class.new { other }, self ]
    end
  end
end
