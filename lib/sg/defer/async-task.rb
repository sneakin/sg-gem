require 'async'
require_relative 'value'

module SG::Defer
  class AsyncTask < Value
    attr_reader :init, :fn
    
    def initialize init = nil, &fn
      @fn = fn
      @init = init
      super() do
        start
        case v = @task.wait
          in [ :error, err ] then raise(err)
          in [ :ok, val ] then val
        end
      end
    end

    def start
      @task ||= Async do
        $stderr.puts("Calling #{self} #{fn.inspect} #{init.inspect}")
        [ :ok, fn.call(*init) ].tap { $stderr.puts("Returning #{_1.inspect}") }
      rescue
        $stderr.puts("Rescued #{$!}")
        [ :error, $! ]
      end
    end
  end
end
