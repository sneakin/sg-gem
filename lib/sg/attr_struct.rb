module SG
  module AttrStruct
    def self.included base
      base.inheritable_attr(:members)
      base.inheritable_attr(:init_values)
      base.extend(ClassMethods)
    end
    
    def initialize *values
      members.zip(values, self.class.init_values || []) { |f, v, iv| self[f] = v || eval_init(iv) }
    end

    def members; self.class.members; end

    def to_a
      members.collect { |m| send(m) }
    end

    def to_hash
      members.reduce({}) { |h, m| h[m] = send(m); h }
    end

    def dup
      self.class.new(*to_a)
    end

    def clone
      c = dup
      members.each do |m|
        c[m] = send(m).clone
      end
      c
    end
    
    alias to_h to_hash

    def each &block
      return to_enum(__method__) unless block
      case block.arity
      when 2 then members.each { |m| block.call(m, send(m)) }
      when 1, -1 then members.each { |m| block.call(send(m)) }
      else raise ArgumentError.new('Arity mismatch: %s != 1, 2, any' % [ block.arity ])
      end
    end
    
    def [] i
      case i
      when Symbol, String then send(i)
      when Integer then send(members[i])
      else raise TypeError.new("Integer, Symbol, String expected")
      end
    end

    def []= i, v
      case i
      when Symbol, String then send("#{i}=", v)
      when Integer then send("#{members[i]}=", v)
      else raise TypeError.new("Integer, Symbol, String expected")
      end
    end

    def == other
      self.class == other.class &&
        members.all? { |m| self[m] == other[m] }
    end

    def != other
      !(self == other)
    end

    def eval_init iv
      case iv
      when Proc then instance_exec(&iv)
      else iv
      end
    end
    
    module ClassMethods
      def inherited base
        self.init_values = init_values.dup
      end
      
      protected
      def attributes *attrs
        if members
          dups = attrs.intersection(members)
          if dups.empty?
            attrs = attrs - members
          else
            raise ArgumentError.new("Duplicate fields added to #{self}: #{dups.inspect}")
          end
        else
          self.members = []
        end
        sz = members.size
        self.members += attrs.each { |a| attr_accessor(a) }
        subclasses.each { |c| c.insert_attributes(sz, *attrs) }
        self
      end

      def insert_attributes where, *attrs
        self.members.insert(where, *attrs)
        self
      end

      def init_attr name, value = nil, &block
        self.init_values ||= []
        init_values[index_for(name)] = value || block
      end

      def index_for attr
        members.index(attr)
      end

      def calc_attr name, value = nil, &block
        define_method(name) do
          v = instance_variable_get("@#{name}")
          return v || eval_init(value || block)
        end
      end
    end
  end
end  
