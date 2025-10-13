require 'thread'
require_relative 'value'
require_relative 'missing'

module SG::Defer
  class Threaded < Value
    include Missing
    def initialize &fn
      @thread = Thread.new(&fn)
      super do
        @thread.join.value
      end
    end
  end
end
