require 'thread'

require 'sg/ext'
using SG::Ext

# todo make Futurable the Able, Able is more Waitable
# todo resolve!/failed! vs accept/reject

module SG::Defer
  autoload :Able, 'sg/defer/able'
  autoload :Acceptorable, 'sg/defer/able'
  autoload :Waitable, 'sg/defer/able'
  autoload :Value, 'sg/defer/value'
  autoload :Missing, 'sg/defer/missing'
  autoload :Proxy, 'sg/defer/proxy'
  autoload :Threaded, 'sg/defer/threaded'
  autoload :Reactor, 'sg/defer/reactor'

  # Rusolve any deferred values contained in simple objects.
  def self.wait_for obj
    case obj
    when Hash then obj.reduce({}) { |h, (k,v)| h[k] = wait_for(v); h }
    when Waitable then obj.wait
    when Enumerable, Array then obj.collect { wait_for(_1) }
    else obj
    end
  end

  # Base error
  class Error < RuntimeError
  end

  # The Futurable was resolved earlier.
  class AlreadyResolved < Error
    attr_reader :value
    def initialize value
      @value = value
      super("Already resolved #{value.class} to #{value.wait rescue $!}")
    end
  end  
end
