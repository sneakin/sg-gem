require 'sg/ext'
using SG::Ext

module SG
  class Assoc
    ERR = Object.new

    attr_reader :elements, :key, :value, :last_match
    
    def initialize elements = [], key: :first, value: nil
      @key = (key || :itself).to_proc
      @value = (value || :itself).to_proc
      @elements = elements
    end

    delegate :<<, :push, :each, :size, :empty?, to: :elements
    def blank?; elements.blank?; end
    
    include Enumerable

    def [] key
      fetch(key, nil)
    end

    def fetch k, default = ERR, &block
      r = elements.find { |e| key.call(e) === k }
      @last_match = $~
      return value.call(r) if r
      raise KeyError.new(k) if default.hash == ERR.hash && block == nil
      return block.call(k) if block
      default
    end    
  end
end
