require 'sg/ext'
using SG::Ext

module SG
  class Assoc
    ERR = Object.new

    attr_reader :elements, :key, :value, :last_match
    
    def initialize elements = [], key: :first, value: nil
      raise TypeError.new("Invalid key accessor: #{key.inspect}") unless is_callable?(key)
      raise TypeError.new("Invalid value accessor: #{value.inspect}") unless is_callable?(value)
      @key = key
      @value = value
      @elements = elements
    end

    delegate :<<, :push, :each, :size, :empty?, :blank?, to: :elements
    include Enumerable

    def [] key
      fetch(key, nil)
    end

    def fetch k, default = ERR, &block
      r = elements.find { |e| key_for(e) === k }
      @last_match = $~
      return value_of(r) if r
      raise KeyError.new(k) if default.hash == ERR.hash && block == nil
      return block.call(k) if block
      default
    end

    private
    
    def key_for el
      callable(key, el)
    end
    
    def value_of r
      callable(value, r)
    end

    def self.callables
      @callables ||= new([ nil, Symbol, String, Proc ], key: nil, value: nil)
    end
    
    def is_callable? fn
      fn == nil || self.class.callables.fetch(fn, false) != false
    end
    
    def callable fn, target
      case fn
      when nil then target
      when Symbol, String then target.send(fn)
      when Proc then fn.call(target)
      else raise TypeError.new('Bad callable value.')
      end
    end
  end
end
