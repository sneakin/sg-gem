require 'thread'

require 'sg/ext'
using SG::Ext

module SG::Defer
  autoload :Able, 'sg/defer/able'
  autoload :Acceptorable, 'sg/defer/able'
  autoload :Waitable, 'sg/defer/able'
  autoload :Value, 'sg/defer/value'
  autoload :Missing, 'sg/defer/missing'
  autoload :Proxy, 'sg/defer/proxy'
  autoload :Threaded, 'sg/defer/threaded'
  autoload :Reactor, 'sg/defer/reactor'

  # Resolve any deferred values contained in enumerable objects.
  def self.wait_for obj, bg: Thread.method(:new), limit: 4
    # todo parallel start before waiting
    # todo in batches, already stalled a pool
    case obj
    when Hash then obj.
        #skip_unless(bg).
        #each { |k, v| bg.call { wait_for(v, bg:, limit:) } if Waitable === v }.
        reduce({}) { |h, (k,v)| h[k] = wait_for(v, bg:, limit:); h }
    when Waitable then obj.wait
    when Enumerable, Array then obj.
        #skip_unless(bg).
        #each_slice(limit) { |s| s.each { |v| bg.call { wait_for(v, bg:, limit:) } if Waitable === v } }.
        collect { wait_for(_1, bg:, limit:) }
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
