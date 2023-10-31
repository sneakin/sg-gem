require 'forwardable'
require 'singleton'
require 'sg/ext'
require 'sg/graph'
require 'sg/method_cache'

module SG  
  class Converter
    class Ignored
      def * other
        other
      end
    end    

    class Identity
      def initialize klass
        @klass = klass
      end
      
      def call inst
        inst
      end
    end

    class NoConverterError < TypeError
      attr_reader :from, :to
      def initialize from, to
        @from = from
        @to = to
        super(to_s)
      end

      def to_s
        "%s(%s, %s)" % [ self.class, from, to]
      end
    end

    GraphEdge = Struct.new(:fn, :weight)
    
    include Singleton

    def converters
      @converters ||= SG::Graph.new
    end

    def register from, to, weight = 1, &block
      converters.rm_edge(from, to).add_edge(from, to, GraphEdge.new(block, weight))
    end

    def for from, to
      if from == to
        Identity.new(from)
      else
        names, edges = converters.route(from, to).
                         sort_by { |e| e[1].sum { |e| e.data.weight } }.
                         first
        raise NoConverterError.new(from, to) unless names
        edges.collect(&:data).collect(&:fn).reduce(Ignored.new, &:*)
      end
    end

    def convert obj, to, *args
      self.for(obj.class, to).call(obj, *args)
    end

    class << self
      extend Forwardable
      def_delegators :instance, :register

      def for from, to
        caching_instance.for(from, to)
      end

      def convert obj, to, *args
        # ensure the cache is used
        self.for(obj.class, to).call(obj, *args)
      end
      
      def caching_instance
        @caching_instance ||= MethodCache.new(instance) do |mc|
          mc.cache(:for)
        end
      end
    end
  end

  module Convertible
    def to klass, *args
      Converter.convert(self, klass, *args)
    end

    def coerce other
      begin
        [ Converter.convert(other, self.class), self ]
      rescue Converter::NoConverterError
        [ other, self.to(other.class) ]
      end
    end
  end
end
