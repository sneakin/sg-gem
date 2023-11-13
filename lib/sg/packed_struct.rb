require 'sg/ext'
require 'sg/attr_struct'
require 'sg/hash_struct'
require 'sg/padding'

# todo array and string fields that use all the data
# todo explicit field offset: data interleaved with fields, trees

module SG
  # Include this to be able to define attributes that get packed
  # into or unpacked from a string of binary data.
  # Attributes are defined using #define_packing.
  module PackedStruct
    using SG::Ext
  
    class UnpackError < RuntimeError
      attr_reader :this, :inst, :data
      def initialize msg, *args
        super(msg)
        @this, @inst, @data = args
      end
    end

    class NoDataError < UnpackError; end
    
    def self.included base
      base.include(HashStruct)
      base.extend(ClassMethods)
    end

    def packer_class; self.class.packer_class; end

    # Packs the object into a string.
    def pack
      packer_class.pack(self)
    end

    # Writes the packed string to an IO.
    def write io
      io.write(pack)
      io
    end

    # Returns the number of bytes the binary will use.
    def bytesize
      packer_class.bytesize(self)
    end

    def attribute_offset name
      packer_class.field_offset(name, self)
    end
    
    # A generic catch all packer string.
    # todo used?
    def packer
      'a%i' % [ bytesize ]
    end
    
    module ClassMethods
      def bytesize inst = nil
        packer_class.bytesize(inst)
      end
      
      def packer inst = nil
        packer_class.packer(inst)
      end

      def pack inst
        packer_class.pack(inst)
      end

      def unpack str
        packer_class.unpack(str, self.new)
      end

      def read io, inst = nil, rest = nil
        inst, new_rest = packer_class.read(io, inst || self.new, rest || '')
        if rest
          [ inst, rest ]
        else
          inst
        end
      end

      def members
        packer_class.field_names
      end

      # Defines the attributes and the types to use when
      # packing the object.
      # The arguments are arrays: `[ name, type, opts* ]`
      # See Packer::Segmenter for the available fields.
      def define_packing *fields
        # add the structure attributes
        if include?(AttrStruct)
          attributes(*fields.
                        reject { |f| f == :super || f[0] == :include }.
                        collect(&:first))
        end
        # include the superclass's packer
        if respond_to?(:packer_class) && !fields.include?(:super)
          fields = [ [ :include, packer_class ], *fields ]
        end
        # create and build, or add to, the Packer
        packer = Packer.build(*fields)
        define_singleton_method(:packer_class) { packer }
        # set packer's instance class to self
        this = self
        packer.define_singleton_method(:instance_class) { this }
        self
      end
    end

    def self.pad_size amount, to = nil
      to ||= 4
      p = amount & (to-1)
      p = to - p if p > 0
      p
    end

    def self.pad n, to = nil
      n + pad_size(n, to)
    end

    # An abstract definition of the types used by the Packer.
    class Type
      # Returns the number of bytes inst will use.
      def bytesize inst = nil
        raise NotImplementedError
      end

      # Returns the string used by Array#pack.
      def packer inst = nil
        raise NotImplementedError
      end

      # Packs the instance into a string.
      def pack inst
        raise NotImplementedError
      end

      # Unpacks a string into an instance.
      def unpack str, inst = nil
        raise NotImplementedError
      end

      def read io, inst, rest
        sz = bytesize(inst)
        str = rest + io.read(sz)
        unpack(str, inst)
      end
    end

    # A wrapper for values Array#pack and String#unpack handle.
    class BasicType < Type
      attr_reader :packer

      def initialize packer, bytesize
        @packer = packer
        @bytesize = bytesize
      end

      def bytesize inst = nil
        @bytesize
      end

      def packer inst = nil
        @packer
      end

      def pack inst
        [ inst ].pack(packer(inst))
      end
      
      def unpack str, inst = nil
        str.unpack(packer(inst) + 'a*')
      end
    end      
    
    # Generate types for /u?int(8|16|32|64)(l|b)?/i
    Types = { c: 8, s: 16, l: 32, q: 64 }.
              reduce({}) do |h, (p, bits)|
      { '' => '', 'l' => '<', 'b' => '>' }.each do |endian, pe|
        h[("int%i%s" % [ bits, endian ]).to_sym] = BasicType.new(p.to_s + pe, bits/8)
        h[("uint%i%s" % [ bits, endian ]).to_sym] = BasicType.new(p.to_s.upcase + pe, bits/8)
      end
      h
    end
    [ [ 32, %w{f e g} ],
      [ 64, %w{d E G} ]
    ].each do |bits, (native, little, big)|
      n = "float%i" % [ bits ]
      Types[n.to_sym] = BasicType.new(native, bits/8)
      Types["#{n}l".to_sym] = BasicType.new(little, bits/8)
      Types["#{n}b".to_sym] = BasicType.new(big, bits/8)
    end
    
    def self.lookup_type type
      case type
      when Integer then Types.fetch(("int%i" % [ type ]).to_sym)
      when String then Types.fetch(type.to_sym)
      when Symbol then Types.fetch(type)
      else type
        #.respond_to?(:packer_class) ?
        #type.packer_class : type
      end
    rescue KeyError
      raise TypeError.new("%s is not a valid field type" % [ type ])
    end

    def self.register_type name, klass
      Types[name] = klass
    end
    
    def self.alias_type base, name
      t = lookup_type(base)
      register_type(name, t)
    end

    # Actual packer field classes.
    
    def self.eval_length length, inst
      case length
      when Symbol then inst ? inst.send(length) : 0
      when Proc then inst ? inst.instance_exec(&length) : 0
      when Integer then length
      when nil then nil
      else raise TypeError
      end
    end

    class Field
      attr_reader :name

      def initialize name
        @name = name
      end

      def field_names
        [ name ]
      end

      def has_field? n
        n == name
      end
      
      def bytesize inst
        raise NotImplementedError
      end

      def offset attr, inst
        return 0 if attr == name
      end
      
      def packer inst
        raise NotImplementedError
      end
      def pack inst
        raise NotImplementedError
      end

      def unpack str, inst
        raise NotImplementedError
      end        

      def read io, inst, rest
        sz = bytesize(inst)
        str = rest + io.read(sz)
        unpack(str, inst)
      end
    end

    class NestedField < Field
      attr_reader :type

      def initialize name, type
        super(name)
        @type = PackedStruct.lookup_type(type)
      end

      def field_names
        type.field_names
      end
      
      def bytesize inst
        type.bytesize(inst)
      end
      
      def packer inst = nil
        type.packer(inst)
      end

      def pack inst
        type.pack(inst)
      end
      
      def unpack str, inst
        bin, r = type.unpack(str, inst)
        raise NoDataError.new("Ran out of data unpacking a #{type.name}") if bin == nil || bin == []
        #puts("%s => %s" % [ name, bin.inspect ])
        inst.update!(bin)
        [ inst, r ]
      end
    end
    
    class ValueField < Field
      attr_reader :type

      def initialize name, type
        super(name)
        @type = PackedStruct.lookup_type(type)
      end

      def bytesize inst
        type.bytesize(inst)
      end
      
      def packer inst = nil
        type.packer(inst)
      end

      def pack inst
        type.pack(inst.send(name))
      end
      
      def unpack str, inst
        bin, r = type.unpack(str)
        raise NoDataError.new("Ran out of data unpacking a #{type.name}") if bin == nil || bin == []
        #puts("%s => %s" % [ name, bin.inspect ])
        inst.update!(name => bin)
        [ inst, r ]
      end
    end

    class SubValueField < ValueField
      def bytesize inst
        type.bytesize(inst ? inst.send(name) : nil)
      end
      
      def packer inst = nil
        type.packer(inst ? inst.send(name) : nil)
      end
    end

    # todo strings and arrays need separate read and write lengths: a string length that uses a field calculated from bytesize; or an error if bytesize is in the length
    
    class StringField < Field
      attr_reader :length, :byte_align

      def initialize name, length, byte_align = nil
        super(name)
        @length = length
        @byte_align = byte_align || 1
      end

      def bytesize inst
        sz = if length
              PackedStruct.eval_length(length, inst)
            else
              inst.send(name).try(:bytesize)
            end || 0
        PackedStruct.pad(sz, byte_align)
      end
      
      def packer inst
        "a%i" % [ bytesize(inst) ]
      end

      def pack inst
        [ inst.send(name) ].pack(packer(inst))
      rescue TypeError
        raise TypeError.new("Incompatible value in :%s" % [ name ])
      end
      
      def unpack str, inst
        bin, r = str.unpack(packer(inst) + 'a*')
        #puts("%s => %s" % [ name, bin.inspect ])
        inst.update!(name => bin)
        [ inst, r ]
      end
    end
    
    class StringZField < Field
      attr_reader :length, :byte_align

      def initialize name, length, byte_align = nil
        super(name)
        @length = length
        @byte_align = byte_align || 1
      end

      def bytesize inst
        value_size = 1 + (inst.send(name).try(:bytesize) || 0)
        len = PackedStruct.eval_length(length, inst)
        PackedStruct.pad(len ? len : value_size, byte_align)
      end
      
      def packer inst
        if length
          "Z%i" % [ bytesize(inst) ]
        else
          "Z*"
        end
      end

      def pack inst
        [ inst.send(name) ].pack(packer(inst))
      rescue TypeError
        raise TypeError.new("Incompatible value in :%s" % [ name ])
      end
      
      def unpack str, inst
        bin, r = str.unpack(packer(inst) + 'a*')
        #puts("%s => %s" % [ name, bin.inspect ])
        inst.update!(name => bin)
        [ inst, r ]
      end
    end
    
    class Segment < Field
      attr_reader :fields

      def initialize *fields
        @fields = fields
        @offsets = {}
      end

      def empty?; fields.empty?; end
      
      def << field
        @fields << field
        self
      end
      
      def field_names
        @field_names ||= fields.collect(&:name)
      end

      def has_field? name
        fields.any? { |f| f.name == name }
      end

      def field_values inst
        field_names.collect { |f| inst.send(f) }
      end

      def field_bytesizes inst
        @field_bytesizes ||= fields.collect { |f| f.bytesize(inst) }
      end
      
      def bytesize inst
        @bytesize ||= field_bytesizes(inst).sum
      end

      def offset name, inst
        ind = fields.index { |f| f.name == name }
        if ind
          @offsets[name] ||= fields[0, ind].collect { |f| f.bytesize(inst) }.sum
        end
      end
      
      def packer inst
        @packer ||= fields.collect { |f| f.packer(inst) }.join
      end

      def packable_value v
        case v
        when PackedStruct then v.pack
        when Array then v.collect { |a| packable_value(a) }
        else v
        end
      end
      
      def promote values
        values.collect { |v| packable_value(v) }
      end
      
      def pack inst
        promote(field_values(inst)).pack(packer(inst))
      end

      def unpack str, inst
        *bin, r = str.unpack(packer(inst) + 'a*')
        #puts str.inspect, packer(inst), bin.inspect, r.inspect
        fn = field_names
        raise NoDataError.new("Ran out of data unpacking a #{inst.class}", self, inst, str) if bin.any?(&:nil?)
        inst.update!(Hash[fn.zip(bin)])
        [ inst, r ]
      end

      def read io, inst, rest
        sz = bytesize(inst)
        str = io.read(sz)
        if str
          str = rest + str
        else
          str = rest || ''
        end
        unpack(str, inst)
      end
    end

    class ArrayField < Field
      attr_reader :type, :length

      def initialize name, type, length
        super(name)
        @type = PackedStruct.lookup_type(type)
        @length = length
      end

      def bytesize inst
        #$stderr.puts("Array bytesize #{name} #{inst.inspect}\n\t#{self.inspect}")
        v = inst.try(name)
        if v && v != []
          v.collect { |e| type.bytesize(e) }.sum
        else
          type.bytesize(v) * (PackedStruct.eval_length(length, inst) || 0)
        end
      end
      
      def packer inst
        #$stderr.puts("packer #{inst}")
        v = inst.try(name)
        if v && v != []
          v.collect { |e| type.packer(e) }.join
        else
          type.packer(v) * PackedStruct.eval_length(length, inst)
        end
      end

      def pack inst
        inst.send(name).collect { |i| type.pack(i) }.join
      end
      
      def unpack str, inst
        arr, rest = PackedStruct.eval_length(length, inst).
                      times.reduce([[], str]) do |(acc, str), n|
          new_inst, r = type.unpack(str)
          #puts("Unpack %i %s: %s\n\t%s" % [ n, name, new_inst.inspect, r.inspect ])
          acc << new_inst
          [ acc, r ]
        end
        inst.update!(name => arr)
        [ inst, rest ]
      end

      def read io, inst, rest
        arr = PackedStruct.eval_length(length, inst).times.reduce([]) do |acc, n|
          new_inst, rest = type.read(io, nil, rest)
          acc << new_inst
          acc
        end

        inst.update!(name => arr)
        [ inst, rest ]
      end
    end

    # The real work horse that uses a set of segments to
    # pack objects and unpack strings.
    class Packer
      attr_reader :segments

      def initialize *segments, &more_segments
        @segments = segments
        @segments += more_segments.call(self) if more_segments
        fields = field_names
        dups = fields.select { |f| fields.count(f) > 1 }
        raise ArgumentError.new("Duplicated field: %s" % [ dups.join(', ') ]) if dups.size > 0
      end

      # todo deep copied?
      def dup
        self.class.new.clone(self)
      end

      def clone other
        @segments = other.segments.dup
        self
      end
      
      def field_names
        segments.collect(&:field_names).flatten
      end

      # todo subclassing may need this flipped around so the PackedStruct creates the Packer, Struct may have to go too.
      
      def instance_class
        this = self
        fns = field_names
        @instance_class ||= Class.new do |s|
          s.include(AttrStruct)
          s.attributes(*fns)
          s.define_singleton_method(:packer_class) { this }
          s.include(PackedStruct)
        end
      end

      def new *init
        instance_class.new(*init)
      end

      def segment_bytesizes inst
        segments.collect do |s|
          s.bytesize(inst) || raise(RuntimeError.new("Nil bytesize: #{s.inspect}"))
        end
      end
      
      def bytesize inst
        segment_bytesizes(inst).sum
      end

      def field_offset name, inst
        segments.reduce(0) do |acc, s|
          off = s.offset(name, inst)
          if off
            break acc + off
          else
            acc + s.bytesize(inst)
          end
        end
      end
      
      def packer inst
        #'a%i' % [ bytesize(inst) ]
        segments.collect { |s| s.packer(inst) }.join
      end

      def packable_value v
        case v
        when PackedStruct then v.to_a
        when Array then v.collect { |a| packable_value(a) }
        else v
        end
      end
      
      def field_values values
        values.collect { |v| packable_value(v) }.flatten
      end
      
      def pack inst
        segments.collect { |s| s.pack(inst) }.join
        # The following may make a huge array and string for #pack
        #field_values(inst.values).pack(packer(inst))
      end

      def unpack str, inst
        rest = segments.reduce(str) do |str, seg|
          _inst, rest = seg.unpack(str, inst)
          rest
        end
        [ inst, rest ]
      end

      def read io, inst, rest = ''
        inst = segments.reduce(inst) do |inst, seg|
          inst, rest = seg.read(io, inst, rest)
          raise RuntimeError.new("Read too much: #{rest.size} #{inst.inspect}") unless rest == nil || rest == ''
          inst
        end

        [ inst, rest ]
      end
      
      class Segmenter
        attr_reader :segments
        
        def initialize packer
          @packer = packer
          @segments = []
          @segment = Segment.new
        end

        def push field = nil
          @segments << @segment unless @segment.empty?
          @segments << field if field
          @segment = Segment.new
          self
        end
        
        def field name, type = nil, *more, **opts
          size = more[0]

          if name == :super
            push(NestedField.new(@packer.class.name, @packer))
          elsif name == :include
            push(NestedField.new(type.instance_class.name, type))
          else
            if type == :string
              push(StringField.new(name, size, opts[:byte_align]))
            elsif type == :stringz
              push(StringZField.new(name, size))
            else
              if size.kind_of?(Proc) ||
                 size.kind_of?(Symbol) ||
                 (size && size > 1)
                push(ArrayField.new(name, type, size))
               elsif size == nil || size >= 0
                if type.kind_of?(Class) || type.kind_of?(Packer)
                  push(SubValueField.new(name, type))
                else
                  @segment << ValueField.new(name, type)
                end
              else raise ArgumentError.new('size must be > 0')
              end
            end
          end
          
          self
        end

        def finish
          push
          segments
        end

        def process *field_defs
          field_defs.each { |fd| field(*fd) }
          finish
        end
      end

      def self.build *field_defs
        self.new { |p| Segmenter.new(p).process(*field_defs) }
      end
    end
    
    def self.new *field_defs
      Packer.build(*field_defs).instance_class
    end
  end
end

if $0 == __FILE__
  S = SG::PackedStruct

  # Basic structure
  if ENV['USENEW'] == '1'
    BP = S::Packer.new(S::Segment.new(S::ValueField.new(:type, :uint16),
                                      S::ValueField.new(:value, :int32b)))
    B = BP.instance_class
  else
    class B
      include SG::AttrStruct
      include S
      define_packing([:type, :uint16b],
                     [:value, :int32b])
    end
  end
  b = B.new(type: 23, value: 9999)
  puts b.inspect
  puts b.packer_class.packer(b)
  puts b.pack.inspect
  puts B.unpack(b.pack + 'and more')

  # Child structures, arrays, dynamic lengths
  if ENV['USENEW'] == '1'
    AP = S::Packer.new(S::Segment.new(S::ValueField.new(:len, :uint16l),
                                     S::ValueField.new(:created, :int64)),
                      S::ValueField.new(:beta, B),
                      S::StringField.new(:data, lambda { len }),
                      S::ArrayField.new(:word, :uint8, 4),
                      S::ArrayField.new(:params, B, lambda { beta.value }))
    A = AP.instance_class
  else
    A = S.new([:len, :uint16l],
              [:created, :int64],
              [:beta, B],
              [:data, :string, lambda { len }],
              [:word, :uint8, 4],
              [:params, B, lambda { beta.value }]
             )
  end
  a = A.new(len: 5, created: Time.now.to_i,
            data: 'hello world',
            beta: B.new(type: 1, value: 3),
            word: [ 10, 20, 30, 40 ],
            params: [ B.new(1,2), B.new(3,4), B.new(5,6) ])
  puts(a.inspect, a.packer, a.to_a.inspect, a.packer_class.packer(a), a.packer_class.field_values(a.to_a).inspect, a.packer_class.segments.inspect)
  s = a.pack
  puts("Packed: %s" % [ s.dump ])
  a1 = A.unpack(s + 'and more')
  puts(a1.inspect)

  # Subclassing
  if ENV['USENEW'] == '1'
    CP = S::Packer.new(S::NestedField.new('B', BP),
                       S::Segment.new(S::StringZField.new(:name, nil),
                                      S::ValueField.new(:ttl, :uint64)))
    C = CP.instance_class
  else
    class C < B
      #attributes :name, :ttl
      define_packing [:name, :stringz], [:ttl, :uint64]
    end
  end

  c = C.new(name: 'XYZ', type: 2, value: -1, ttl: 60)
  puts(c.inspect)
  puts(c.packer_class == C.packer_class)
  puts(C.packer_class.field_names.inspect,
       C.packer_class.inspect,
       C.packer(c))
  s = c.pack
  puts(c.pack.inspect, C.pack(c).inspect)
  puts(C.unpack(s).inspect)
end
