require 'sg/packed_struct'
require_relative 'packed_struct/data'

describe SG::PackedStruct do
  alpha = PackedStructSpec::Alpha
  beta = PackedStructSpec::Beta
  
  let(:pack_str) { 'CS<s>lQ<C4a5a10a10a10' }
  let(:values) { [ 1, 2, 3, 4, 5,
                   'heyo'.unpack('C*'),
                   'world',
                   beta.new(30, 0x1122334455677788),
                   [ beta.new(10, 0x1234), beta.new(20, 0x4567) ]
                 ] }
  
  describe '.minsize' do
    it 'returns the minimum bytes for a packed instance' do
      expect(alpha.bytesize).to eq(27)
    end
  end

  def pack_values values
    values.collect do |v|
      case v
      when SG::PackedStruct then v.pack
      when Array then
        if v[0].kind_of?(SG::PackedStruct)
          v.collect(&:pack)
        else
          v
        end
      else v
      end
    end.flatten.pack(pack_str)
  end

  describe 'without initial values' do
    subject { alpha.new }
    
    it 'uses init_value when provided' do
      expect(subject.c).to eq(123)
    end

    it 'uses value with an init_value' do
      expect(subject.d).to eq(456)
    end
  end
  
  describe 'initialized by array' do
    subject { alpha.new(*values) }

    describe '#bytesize' do
      it 'returns the number of bytes for a packed instance' do
        expect(subject.bytesize).to eq(56)
      end
    end
    
    describe '#pack' do
      it 'returns a string' do
        expect(subject.pack).
          to eq(pack_values(values))
      end
    end

    describe '#write' do
      let(:io) { StringIO.new.tap { |io| io.set_encoding('ASCII') } }
      
      it 'writes the packed data to the stream' do
        expect { subject.write(io) }.
          to change { io.string.bytesize }.to(subject.pack.bytesize)
      end

      it 'writes the packed data to the stream' do
        expect { subject.write(io) }.
          to change { io.string.bytes }.to(subject.pack.bytes)
      end
      
      it 'returns the stream' do
        expect(subject.write(io)).to eq(io)
      end
    end

    describe '#each' do
      it 'returns an enumerable with no block' do
        expect(subject.each).to be_kind_of(Enumerable)
        expect(subject.each.to_a).to eq(subject.to_a)
      end
      
      it 'passes each value a single argument block' do
        vals = []
        subject.each { |v| vals << v }
        expect(vals).to eq(subject.to_a)
      end
      
      it 'passes the attribute and value with a two argument block' do
        vals = {}
        subject.each { |k,v| vals[k] = v }
        expect(vals).to eq(subject.to_hash)
      end
    end

    describe '#attribute_offset' do
      let(:sizes) { [ 1, 2, 2, 4, 8, 4, 5, 10, 10 ] }
      let(:offsets) do
        sizes.reduce([[], 0]) do |(arr, here), sz|
          arr << here
          [ arr, here + sz ]
        end.first
      end

      it 'returns the byte offset for each field' do
        offs = subject.class.members.collect do |attr|
          subject.attribute_offset(attr)
        end
        expect(offs).to eq(offsets)
      end
    end
  end

  describe 'field type' do
    # todo way to set default endian
    data = {
      int8: [ 0x7b, "\x7b" ],
      int16: [ 0x7b, "\x7b\x00" ],
      int16l: [ 0x7b, "\x7b\x00" ],
      int16b: [ 0x7b, "\x00\x7b" ],
      int32: [ 0x7b, "\x7b\x00\x00\x00" ],
      int32l: [ 0x7b, "\x7b\x00\x00\x00" ],
      int32b: [ 0x7b, "\x00\x00\x00\x7b" ],
      int64: [ 0x7b, "\x7b\x00\x00\x00\x00\x00\x00\x00" ],
      int64l: [ 0x7b, "\x7b\x00\x00\x00\x00\x00\x00\x00" ],
      int64b: [ 0x7b, "\x00\x00\x00\x00\x00\x00\x00\x7b" ],
      float32: [ 1.23, "\xA4p\x9D?" ],
      float32l: [ 1.23, "\xA4p\x9D?" ],
      float32b: [ 1.23, "?\x9Dp\xA4" ],
      float64: [ 1.23, "\xAEG\xE1z\x14\xAE\xF3?" ],
      float64l: [ 1.23, "\xAEG\xE1z\x14\xAE\xF3?" ],
      float64b: [ 1.23, "?\xF3\xAE\x14z\xE1G\xAE" ],
    }
    # Add unsigned ints
    data.
      select { |k,v| k.to_s =~ /^int/ }.
      each { |k, v| data["u#{k}".to_sym] = v }

    data.each do |type, (value, packed)|
      packed.force_encoding('ASCII-8BIT')
      describe "a #{type} of #{value}" do
        let(:klass) do
          Class.new do
            include SG::AttrStruct
            include SG::PackedStruct
            define_packing [ :n, type ]
          end
        end

        subject { klass.new(n: value) }

        it "packs to #{packed.inspect}" do
          expect(subject.pack).to eq(packed)
        end
      end
    end
  end
  
  describe 'initialized by hash' do
    let(:values) do
      { a: 1, b: 2, c: 3, d: 4, e: 5,
        f: 'hmm.'.unpack('C*'),
        g: 'world',
        h: beta.new(type: 30, value: 0x1122334455667788),
        i: [ beta.new(10, 0x1234), beta.new(20, 0x4567) ]
      }
    end
    let(:inst) { alpha.new(values) }

    it 'assigns the attributes' do
      expect(inst.a).to eq(values[:a])
      expect(inst.b).to eq(values[:b])
      expect(inst.c).to eq(values[:c])
      expect(inst.d).to eq(values[:d])
      expect(inst.e).to eq(values[:e])
      expect(inst.f).to eq(values[:f])
      expect(inst.g).to eq(values[:g])
      expect(inst.h).to eq(values[:h])
      expect(inst.i).to eq(values[:i])
    end
  end

  describe '.unpack' do
    describe 'with valid data' do
      before(:each) do
        bin = pack_values(values) + 'And more.'
        @alpha, @leftover = alpha.unpack(bin)
      end
      
      it 'returns an instance' do
        expect(@alpha).to be_kind_of(alpha)
      end

      it 'returns the left overs' do
        expect(@leftover).to eq('And more.')
      end

      it 'assigns the attributes' do
        expect(@alpha.a).to eq(values[0])
        expect(@alpha.b).to eq(values[1])
        expect(@alpha.c).to eq(values[2])
        expect(@alpha.d).to eq(values[3])
        expect(@alpha.e).to eq(values[4])
        expect(@alpha.f).to eq(values[5])
        expect(@alpha.g).to eq(values[6])
        expect(@alpha.h).to eq(values[7])
        #expect(@alpha.i).to eq(values[8])
      end

      it 'unpacked the beta field' do
        expect(@alpha.h).to be_kind_of(beta)
      end
      
      it 'unpacked the basic array with the right length' do
        expect(@alpha.f.size).to eq(@alpha.a * 4)
      end
      
      it 'unpacked the string with the right length' do
        expect(@alpha.g.size).to eq(@alpha.e)
      end

      it 'unpacked the item array with the right length' do
        expect(@alpha.i.size).to eq(@alpha.b)
      end
    end

    describe 'with not enough data' do
      let(:bin) do
        bin = pack_values(values)
        bin[0, bin.size/3]
      end

      it 'raises an error' do
        expect { alpha.unpack(bin) }.
          to raise_error(SG::PackedStruct::NoDataError)
      end
    end
  end

  describe '.read' do
    let(:io) { StringIO.new(pack_values(values) + ' and more') }
    
    it 'returns an instance and remaining data' do
      expect(alpha.read(io)).to be_kind_of(alpha)
    end

    let(:inst) { alpha.read(io) }
    
    it 'assigns the attributes' do
      expect(inst.a).to eq(values[0])
      expect(inst.b).to eq(values[1])
      expect(inst.c).to eq(values[2])
      expect(inst.d).to eq(values[3])
      expect(inst.e).to eq(values[4])
      expect(inst.f).to eq(values[5])
      expect(inst.g).to eq(values[6])
      expect(inst.h).to eq(values[7])
      expect(inst.i).to eq(values[8])
    end

    it 'leaves the stream in position' do
      expect(inst && io.read).to eq(' and more')
    end
  end

  describe 'a statically sized struct' do
    let(:inst) do
      beta.new(type: 123,
               value: 789)
    end

    describe '.unpack' do
      it 'works' do
        expect(beta.unpack(inst.pack)).to eq([inst,''])
      end
    end

    describe '.read' do
      it 'works' do
        io = StringIO.new(inst.pack)
        expect(beta.read(io)).to eq(inst)
      end
    end
  end

  describe 'with a duplicate field' do
    it 'raises an error' do
      expect do
        described_class.new([:a, :uint8], [:b, :uint16], [:a, :uint16])
      end.to raise_error(ArgumentError)
    end
  end

  describe 'with a bad type' do
    it 'raises an error' do
      expect do
        described_class.new([:a, :uint8], [:b, :uint16], [:c, :boom])
      end.to raise_error(TypeError)
    end
  end

  describe 'subclassing w/o :super' do
    let(:subclass) do
      c = Class.new(beta) do
        define_packing([:desc, :stringz],
                       [:ranking, :float32])
      end
    end

    let(:instance) { subclass.new(type: 12, value: 34, desc: 'a test', ranking: 4) }
    
    describe 'the class' do
      subject { subclass }
      
      it 'has a subclassed Packer class' do
        expect(subject.packer_class).to_not eq(beta.packer_class)
        expect(subject.packer_class).to be_kind_of(beta.packer_class.class)
      end
      
      it 'has the parent attributes' do
        attr = subject.members
        expect(attr).to include(:type)
        expect(attr).to include(:value)
      end

      it 'has the the added attributes' do
        attr = subject.members
        expect(attr).to include(:desc)
        expect(attr).to include(:ranking)
      end

      it 'unpacks' do
        packing = instance.pack + 'and more'
        expect(subject.unpack(packing)).
          to eq([ subject.new(12, 34, 'a test', 4), 'and more'])
      end
    end

    describe 'an instance' do
      subject { instance }
      
      it 'packs with the parent attrs first' do
        expect(subject.pack).
          to eq([ 12, 34, 'a test', 4 ].pack('s<q<Z*e'))
      end
    end  
  end

  describe 'a nested object with a functional length' do
    let(:nested) do
      Class.new do
        include SG::AttrStruct
        include SG::PackedStruct
        define_packing [:size, :int32],
                       [:values, :int32, :size]
        calc_attr :size, lambda { values.size }
      end
    end
    let(:container) do
      n = nested
      Class.new do
        include SG::AttrStruct
        include SG::PackedStruct
        define_packing [:len, :uint16],
                       [:nobjects, :int32],
                       [:objects, n, :nobjects]
        calc_attr :len, lambda { bytesize / 4 }
        calc_attr :nobjects, lambda { objects.size }
      end
    end
    let(:exp) do
      "\n\x00\x02\x00\x00\x00\x03\x00\x00\x00\x10\x00\x00\x00 \x00\x00\x00@\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x05\x00\x00\x00\x06\x00\x00\x00\a\x00\x00\x00".force_encoding('ASCII-8BIT')
    end
    
    subject do
      container.new(objects: [ nested.new(values: [16,32,64]),
                               nested.new(values: [4,5,6,7])
                             ])
    end
    
    it 'packs' do
      expect(subject.pack).to eq(exp)
    end
    
    it 'unpacks' do
      expect(container.unpack(exp)).to eq([ subject, '' ])
    end
  end

  describe 'a nested object with an array of objects' do
    let(:very_nested) do
      Class.new do
        include SG::AttrStruct
        include SG::PackedStruct
        define_packing [:size, :int32],
                       [:values, :int32, :size]
        calc_attr :size, lambda { values.size }
      end
    end
    let(:nested) do
      vn = very_nested
      Class.new do
        include SG::AttrStruct
        include SG::PackedStruct
        define_packing [:size, :int32],
                       [:values, vn, :size]
        calc_attr :size, lambda { values.size }
      end
    end
    let(:container) do
      n = nested
      Class.new do
        include SG::AttrStruct
        include SG::PackedStruct
        define_packing [:len, :uint16],
                       [:nobjects, :int32],
                       [:objects, n, :nobjects]
        calc_attr :len, lambda { bytesize / 4 }
        calc_attr :nobjects, lambda { objects.size }
      end
    end
    let(:exp) do
      "\x11\x00\x02\x00\x00\x00\x02\x00\x00\x00\x03\x00\x00\x00\x10\x00\x00\x00 \x00\x00\x00@\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\x05\x00\x00\x00\x06\x00\x00\x00\a\x00\x00\x00\x02\x00\x00\x00\x01\x00\x00\x00?\x00\x00\x00\x02\x00\x00\x00\x7F\x00\x00\x00\xFF\x00\x00\x00".force_encoding('ASCII-8BIT')
    end
    
    subject do
      container.new(objects: [
                      nested.
                        new(values: [
                              very_nested.new(values: [16,32,64]),
                              very_nested.new(values: [4,5,6,7])
                            ]),
                      nested.
                        new(values: [
                              very_nested.new(values: [63]),
                              very_nested.new(values: [127,255])
                            ])
                    ])
    end
    
    it 'packs' do
      p = subject.pack
      expect(p).to eq(exp)
    end
    
    it 'unpacks' do
      o = container.unpack(exp)
      expect(container.unpack(exp)).to eq([ subject, '' ])
    end

    it 'can be written' do
      io = StringIO.new
      subject.write(io)      
      expect(io.string.force_encoding('ASCII-8BIT')).to eq(exp)
    end

    it 'can be read' do
      io = StringIO.new(exp)
      expect(container.read(io)).to eq(subject)
    end
  end  

  describe 'when a string length is a field' do
    struct = Class.new do
      include SG::AttrStruct
      include SG::PackedStruct
      define_packing [:size, :int32],
                     [:value, :string, :size ]
      calc_attr :size, lambda { value.bytesize }
    end

    [ [ 5, 'hello', 'la*' ],
      [ 0, '', 'la*' ]
    ].each do |(size, value, packer)|
      describe "with #{value.inspect}" do
        subject { struct.new(size:, value:) }

        it 'packs' do
          expect(subject.pack).to eq([ size, value ].pack(packer))
        end

        it 'unpacks' do
          expect(struct.unpack([ size, value ].pack(packer))).
            to eq([subject, ''])
        end

        it 'round trips' do
          expect(struct.unpack(subject.pack)). to eq([subject, ''])
        end
      end
    end

    describe 'nested in another struct' do
      let(:bigstruct) do
        Class.new do
          include SG::AttrStruct
          include SG::PackedStruct
          define_packing [:size, :uint16],
                         [:a, struct ],
                         [:b, struct ]
          calc_attr :size, lambda { a.bytesize + b.bytesize }
        end
      end
      
      [ [ 8, '', '' ],
        [ 11, '', 'hello' ],
        [ 11, 'hello', '' ],
        [ 18, 'hello', 'hello' ]
      ].each do |(size, avalue, bvalue)|
        describe "with #{avalue.inspect} and #{bvalue.inspect}" do
          subject { bigstruct.new(size: size,
                                  a: struct.new(size: avalue.size, value: avalue),
                                  b: struct.new(size: bvalue.size, value: bvalue)) }

          it 'packs' do
            expect(subject.pack).to eq([ size, avalue.size, avalue, bvalue.size, bvalue ].pack('sla*la*'))
          end

          it 'unpacks' do
            expect(bigstruct.unpack([ size, avalue.size, avalue, bvalue.size, bvalue ].pack('sla*la*'))).
              to eq([subject, ''])
          end

          it 'round trips' do
            expect(bigstruct.unpack(subject.pack)). to eq([subject, ''])
          end
        end
      end
    end
  end

  describe 'when a string length uses bytesize' do
    let(:struct) do
      Class.new do
        include SG::AttrStruct
        include SG::PackedStruct
        define_packing [:size, :int32],
                       [:value, :string, lambda { size - 4 } ] # stack overflow w/ bytesize
        calc_attr :size, lambda { bytesize }
      end
    end

    describe 'with hello' do
      subject { struct.new(size: 9, value: 'hello') }

      it 'packs' do
        expect(subject.pack).to eq([ 9, "hello" ].pack('la*'))
      end

      it 'unpacks' do
        expect(struct.unpack([ 9, "hello" ].pack('la*'))).
          to eq([subject, ''])
      end
    end

    describe 'with ""' do
      subject { struct.new(size: 4, value: '') }

      it 'packs' do
        expect(subject.pack).to eq([ 4, "" ].pack('la*'))
      end

      it 'unpacks' do
        expect(struct.unpack([ 4, "" ].pack('la*'))).
          to eq([subject, ''])
      end
    end
  end

  describe 'padded at the end' do
    let(:struct) do
      Class.new do
        include SG::AttrStruct
        include SG::PackedStruct
        define_packing [:size, :int32],
                       [:value, :string, :size ],
                       [:padding, :string, lambda { SG::PackedStruct.pad_size(size) } ]
        calc_attr :size, lambda { value.bytesize }
        calc_attr :padding, lambda { "\x00" * SG::PackedStruct.pad_size(size) }
      end
    end

    [ [ 'hello', [ 5, "hello", "\x00\x00\x00" ] ],
      [ 'foo', [ 3, "foo", "\x00" ] ],
      [ '', [ 0, "", "" ] ],
      [ 'boom', [ 4, 'boom', '' ] ]
    ].each do |(value, attrs)|
      packed_attrs = attrs.pack('la*a*')
      describe "with a value of #{value.dump}" do
        let(:packing) { packed_attrs }
        subject { struct.new(value: value) }

        it "packs to #{packed_attrs.inspect}" do
          packed = subject.pack
          expect(packed).to eq(packing)
        end

        it "packs to #{attrs[0] + 4} bytes with padding" do
          packed = subject.pack
          expect(packing.bytesize).
            to eq(subject.size + 4 + SG::PackedStruct.pad_size(subject.size))
        end

        it 'unpacks' do
          expect(struct.unpack(packing)).to eq([subject, ''])
        end
      end
    end
  end

  shared_examples 'packed padded string' do |value:, attrs:, packer:|
    packed_attrs = attrs.pack(packer)
    describe "with a value of #{value.dump}" do
      let(:packing) { packed_attrs }
      subject { struct.new(value: value) }

      it "packs to #{packed_attrs.inspect}" do
        packed = subject.pack
        expect(packed).to eq(packing)
      end
      
      it "packs to #{attrs[0] * 4} bytes" do
        packed = subject.pack
        expect(packing.bytesize).to eq(subject.size * 4)
      end

      it 'unpacks' do
        expect(struct.unpack(packing)).to eq([subject, ''])
      end
    end      
  end

  shared_examples 'packed padded strings' do |packer, values|
    values.each do |(value, attrs)|
      it_behaves_like 'packed padded string', value: value, attrs: attrs, packer: packer
    end
  end
  
  describe 'padded by rounding the size' do
    let(:struct) do
      Class.new do
        include SG::AttrStruct
        include SG::PackedStruct
        define_packing [:size, :int32],
                       [:value, :stringz ],
                       [:padding, :string, lambda { SG::PackedStruct.pad_size(value.bytesize + 1) } ]
        calc_attr :size do
          (4 + value.bytesize + 1 + SG::PackedStruct.pad_size(value.bytesize + 1)) / 4
        end
        calc_attr :padding do
          "\x00" * SG::PackedStruct.pad_size(value.bytesize + 1)
        end
      end
    end

    it 'packs with a zero terminated string' do
      #binding.break
      expect(struct.packer(struct.new(value: "hello"))).to eq('lZ*a2')
    end
    
    it 'unpacks with a zero terminated string' do
      inst = struct.new(size: 2, value: 'boom')
      expect(struct.packer_class.segments.collect { |s| s.packer(inst) }).to eq(%w{l Z* a3})
    end
    
    it_behaves_like 'packed padded strings', "lZ*a*",
                    [ [ 'hello', [ 3, "hello", "\x00\x00" ] ],
                      [ 'foo', [ 2, "foo", "" ] ],
                      [ '', [ 2, "", "\x00\x00\x00" ] ],
                      [ 'boom', [ 3, "boom", "\x00\x00\x00" ] ]
                    ]
  end  

  describe 'padded by using an offset' do
    let(:struct) do
      Class.new do
        include SG::AttrStruct
        include SG::PackedStruct
        define_packing [:size, :int32],
                       [:value, :stringz ],
                       [:padding, :string, lambda { SG::PackedStruct.pad_size(attribute_offset(:padding)) } ]
        calc_attr :size do
          bytesize / 4
        end
        calc_attr :padding do
          "\x00" * SG::PackedStruct.pad_size(attribute_offset(:padding))
        end
      end
    end

    it 'packs with a zero terminated string' do
      expect(struct.packer(struct.new(value: "hello"))).
        to eq('lZ*a2')
    end
    
    it 'unpacks with a zero terminated string' do
      inst = struct.new(size: 2, value: 'boom')
      expect(struct.packer_class.segments.
               collect { |s| s.packer(inst) }).
        to eq(%w{l Z* a3})
    end
    
    it_behaves_like 'packed padded strings', 'lZ*a*',
                    [ [ 'hello', [ 3, "hello", "\x00\x00" ] ],
                      [ 'foo', [ 2, "foo", "" ] ],
                      [ '', [ 2, "", "\x00\x00\x00" ] ],
                      [ 'boom', [ 3, "boom", "\x00\x00\x00" ] ]
                    ]
  end  

  describe 'padded by using a sized zero terminated string' do
    let(:struct) do
      Class.new do
        include SG::AttrStruct
        include SG::PackedStruct
        define_packing [:size, :int32],
                       [:value, :stringz, lambda { size * 4 - attribute_offset(:value) } ]
        calc_attr :size do
          SG::PackedStruct.pad(1 + attribute_offset(:value) + value.bytesize) / 4
        end
      end
    end

    it 'offset value' do
      expect(struct.new.attribute_offset(:value)).to eq(4)
    end
    
    it 'packs with a zero terminated string' do
      expect(struct.packer(struct.new(value: "hello"))).
        to eq('lZ8')
    end
    
    it 'unpacks with a zero terminated string' do
      inst = struct.new(size: 2, value: 'boom')
      expect(struct.packer_class.segments.
               collect { |s| s.packer(inst) }).
        to eq(%w{l Z4})
    end
    
    it_behaves_like 'packed padded strings', 'lZ*a*',
                    [ [ 'hello', [ 3, "hello", "\x00\x00" ] ],
                      [ 'foo', [ 2, "foo", "" ] ],
                      [ '', [ 2, "", "\x00\x00\x00" ] ],
                      [ 'boom', [ 3, "boom", "\x00\x00\x00" ] ]
                    ]
  end  
  
  describe 'with a byte aligned string' do
    let(:struct) do
      Class.new do
        include SG::AttrStruct
        include SG::PackedStruct
        define_packing [:size, :int32],
                       [:name, :string, :size, byte_align: 32 ]
      end
      
      subject { struct.new(name: 'Bob') }

      it 'only calculates with the stripped value' do
        expect(subject.size).to eq(3)
      end
            
      it 'pads the attribute when packed' do
        expect(subject.pack).to eq("\x03Bob" + "\x00" * 28)
      end
      
      it 'unpacks the padding' do
        packed = subject.pack
        other = struct.unpack(packed)
        expect(other.name).to eq("Bob")
      end
    end
  end

  describe 'with a byte aligned zero terminated string' do
    let(:struct) do
      Class.new do
        include SG::AttrStruct
        include SG::PackedStruct
        define_packing [:size, :int32],
                       [:name, :stringz, :size, byte_align: 21 ]
      end
      
      subject { struct.new(name: 'Bob') }

      it 'only calculates with the stripped value' do
        expect(subject.size).to eq(3)
      end
            
      it 'pads the attribute when packed' do
        expect(subject.pack).to eq("\x03Bob" + "\x00" * (21-4))
      end
      
      it 'unpacks the padding' do
        packed = subject.pack
        other = struct.unpack(packed)
        expect(other.name).to eq("Bob")
      end
    end
  end
end
