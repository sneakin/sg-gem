require 'sg/ext'
using SG::Ext

require 'thread'
require_relative 'value'

module SG::Defer
  # A {Defer::Value} synchronized by {Mutex} with a {ConditionVariable}
  # providing ready signaling.
  class ConditionValue < Value
    attr_reader :timeout
    
    def initialize timeout: nil, &fn
      @mut = Mutex.new
      @cv = ConditionVariable.new
      @timeout = timeout
      super(&(fn || lambda { |_| wait_ready }))
    end

    def reset!
      @mut.synchronize do
        super
      end
    end
    def accept v
      @mut.synchronize do
        super.tap { @cv.broadcast }
      end
    end
    def reject v
      @mut.synchronize do
        super.tap { @cv.broadcast }
      end
    end

    def wait_ready secs = timeout
      @mut.synchronize do
        @cv.wait(@mut, secs) until secs != nil || ready?
      end
      self
    end
  end
end
