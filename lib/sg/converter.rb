require 'forwardable'
require 'singleton'
require 'json'
require 'sg/ext'
require 'sg/graph'
require 'sg/method_cache'
require 'sg/fun'
require 'sg/ignored'

using SG::Ext

module SG
  class Converter
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
        SG::Fun::Identity
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

      def register from, to, weight = 1, &block
        caching_instance.
          invalidate_cache(:for, from, to).
          invalidate_cache(:for, to, from)
        instance.register(from, to, weight, &block)
      end
      
      def register_scaler from, to, factor, offset = 0
        register(from, to) do |c|
          to.new((c.value + offset) * factor)
        end
        register(to, from) do |f|
          from.new((f.value / factor) - offset)
        end
      end
    end
  end

  module Convertible
    def to klass, *args
      Converter.convert(self, klass, *args)
    end

    # def coerce other
    #   begin
    #     [ Converter.convert(other, self.class), self ]
    #   rescue Converter::NoConverterError
    #     [ other, self.to(other.class) ]
    #   end
    # end
  end
end

#
# Monkey patch Object
#

module SG::Ext
  [ ::String, ::Integer, ::Float ].each do |klass|
    refine klass do
      begin
        import_methods SG::Convertible
      rescue NoMethodError
        begin
          include SG::Convertible
        rescue TypeError
          warn("SG::Convertible unavailable.")
        end
      end
    end
  end
end

#
# Basic type conversions
#

SG::Converter.register(String, Integer, &:to_i)
SG::Converter.register(String, Float, &:to_f)
SG::Converter.register(String, Complex) do |s|
  case s
  when /\A([-+]?[^-+,]+)\s*([-+, ])?\s*([^i]+)i?/ then
    Complex.rect($1.to_f, $3.to_f.then { |n| $2 == '-' ? -n : n })
  else raise ArgumentError, "#{s.inspect} not Complex"
  end
end

SG::Converter.register(Integer, String, &:to_s)
SG::Converter.register(Integer, Float, &:to_f)
SG::Converter.register(Integer, Complex) { |x| Complex.rect(x, 0) }
    
SG::Converter.register(Float, String, &:to_s)
SG::Converter.register(Float, Integer, &:to_f)
SG::Converter.register(Float, Complex) { |x| Complex.rect(x, 0) }

SG::Converter.register(Complex, String, &:to_s)
SG::Converter.register(Complex, Integer, &:real)
SG::Converter.register(Complex, Float, &:real)

SG::Converter.register(Array, String, &:inspect)
#SG::Converter.register(String, Array) { |s| eval(s) }

SG::Converter.register(Hash, String, &:inspect)
#SG::Converter.register(String, Hash) { |s| eval(s) }

SG::Converter.register(Hash, JSON, &:to_json)
SG::Converter.register(Array, JSON, &:to_json)
SG::Converter.register(String, JSON) { |s| JSON.load(s) }
