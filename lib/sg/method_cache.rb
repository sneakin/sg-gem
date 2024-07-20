require 'sg/ext'
using SG::Ext

module SG
  class MethodCache
    class Builder
      attr_reader :caching
      
      def initialize
        @caching = []
      end

      def cache mid
        @caching << mid
      end
    end
    
    def initialize obj
      @obj = obj
      @cache = Hash.new { |h, k| h[k] = Hash.new }
      @caching = []
      if block_given?
        b = Builder.new
        yield(b)
        @caching = b.caching
      end
    end

    def caching? mid
      @caching.include?(mid)
    end

    def cached_yield mid, args, call_block, &block
      s = args + [ call_block ]
      r = @cache[mid][s]
      return r if r
      r = block.call
      @cache[mid][s] = r
      r
    end

    def method_missing mid, *args, &block
      if caching?(mid)
        cached_yield(mid, args, block) do
          @obj.send(mid, *args, &block)
        end
      else
        @obj.send(mid, *args, &block)
      end
    end
  end
end
