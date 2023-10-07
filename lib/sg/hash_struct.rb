module SG
  module HashStruct
    def initialize *values
      if values[0].kind_of?(Hash)
        h = values[0]
        values = self.members.collect { |a| h[a] }
      end
      super(*values)
    end

    def to_a; members.collect { |m| send(m) }; end

    def update! *values
      case values[0]
      when HashStruct
        values[0].each.with_index { |v, n| self[n] = v }
      when Hash then
        h = values[0]
        h.each { |k,v| self[k] = v }
      else
        if values.size > members.size
          raise ArgumentError.new("Expected %i arguments. Got %i." %
                                  [ members.size, values.size ])
        end
        values.each.with_index { |v, n| self[n] = v }
      end

      return self
    end    

    def self.new *fields
      klass = Struct.new(*fields)
      klass.include(HashStruct)
      klass
    end
  end
end
