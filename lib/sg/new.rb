require 'sg/ext'

using SG::Ext

module SG
  class New
    attr_reader :maker
    
    def initialize klass = nil, &maker
      raise ArgumentError if klass == nil && maker == nil
      @maker = maker || lambda { |*a, **o, &b| klass.new(*a, **o, &b) }
    end

    def new *a, **o, &b
      maker.call(*a, **o, &b)
    end

    alias [] :new

    def self.[] klass
      self.new(klass)
    end
  end
end
