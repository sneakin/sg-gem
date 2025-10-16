require 'thread'
require_relative 'value'
require_relative 'missing'

module SG::Defer
  class Threaded < Value
    include Missing
    def initialize init = nil, &fn
      @thread = Thread.new(*init) do |*a|
        [ :ok, fn.call(*a) ]
      rescue
        [ :error, $! ]
      end
      super() do
        case v = @thread.value
          in [ :error, err ] then raise(err)
          in [ :ok, val ] then val
        else raise TypeError.new("Unknown return: #{v.inspect}")
        end
      end
    end
  end
end
