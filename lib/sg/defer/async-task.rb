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
        [ :ok, fn.call(*init) ]
      rescue
        [ :error, $! ]
      end
    end
  end
end
