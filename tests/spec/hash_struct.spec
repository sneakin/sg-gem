require 'sg/hash_struct'

describe SG::HashStruct do
  class TestHS < SG::HashStruct.new(:type, :value, :ttl)
  end

  describe 'no initializers' do
    subject { TestHS.new }

    it { should be_kind_of(described_class) }
    it { should be_kind_of(Struct) }
    
    it 'assigns the attributes' do
      expect(subject.type).to eq(nil)
      expect(subject.value).to eq(nil)
      expect(subject.ttl).to eq(nil)
    end
  end
  
  describe 'initialized by array' do
    let(:values) { [ 2, 3, 4 ] }
    subject { TestHS.new(*values) }

    it 'assigns the attributes' do
      expect(subject.type).to eq(values[0])
      expect(subject.value).to eq(values[1])
      expect(subject.ttl).to eq(values[2])
    end
  end

  describe 'initialized by hash' do
    subject { TestHS.new(values) }

    describe 'valid keys' do
      let(:values) do
        { type: 12, value: 1234 }
      end
      
      it 'assigns the attributes' do
        expect(subject.type).to eq(values[:type])
        expect(subject.value).to eq(values[:value])
        expect(subject.ttl).to eq(nil)
      end
    end

    describe 'invalid key' do
      let(:values) { { type: 12, value: 4, bad: 4, ttl: 55 } }

      it 'assigns the attributes' do
        expect(subject.type).to eq(values[:type])
        expect(subject.value).to eq(values[:value])
        expect(subject.ttl).to eq(values[:ttl])
      end
    end
  end

  describe '#update!' do
    subject { TestHS.new }
    
    describe 'with arguments' do
      it { expect { subject.update!(1,2,3) }.
             to change { subject.values }.to([1, 2, 3]) }
    end

    describe 'with too many arguments' do
      it { expect { subject.update!(1,2,3,4) }.
             to raise_error(ArgumentError) }
    end

    describe 'with a hash' do
      it { expect { subject.update!(type: 1, value: 2, ttl: 3) }.
             to change { subject.values }.to([1, 2, 3]) }
    end
    
    describe 'with another instance' do
      it {
        expect {
          subject.update!(TestHS.new(type: 1, value: 2, ttl: 3))
        }.to change { subject.to_a }.to([1, 2, 3])
      }
    end
  end
end
