require 'sg/packed_struct'

describe SG::AttrStruct do
  module AttrStructSpec
    class Alpha
      include SG::AttrStruct
      attributes :name, :age
      init_attr :name, 'John Doe'
      init_attr :age, 0
    end
  end

  describe 'direct descendent' do
    subject { AttrStructSpec::Alpha.new('Bob', 32) }

    it { expect(subject.members).to eq([:name, :age]) }
    it { expect(subject.to_a).to eq(['Bob', 32]) }    

    it 'has readers' do
      expect(subject.name).to eq('Bob')
      expect(subject.age).to eq(32)
    end

    it 'has writers' do
      expect { subject.name = 'Robert' }.
        to change { subject.name }.from('Bob').to('Robert')
      expect { subject.age = 33 }.
        to change { subject.age }.from(32).to(33)
    end
    
    describe '#[]' do
      describe 'with integers' do
        it 'returns each member value in the order members were added' do
          expect(subject[0]).to eq('Bob')
          expect(subject[1]).to eq(32)
        end
      end
      describe 'with symbols' do
        it 'returns the value of the named member' do
          expect(subject[:name]).to eq('Bob')
          expect(subject[:age]).to eq(32)
        end
      end
      describe 'with strings' do
        it 'returns the value of the named member' do
          expect(subject['name']).to eq('Bob')
          expect(subject['age']).to eq(32)
        end
      end        
    end

    describe '#[]=' do
      describe 'with integers' do
        it 'returns each member value in the order members were added' do
          expect { subject[0] = 'Robert' }.
            to change { subject.name }.to('Robert')
          expect { subject[1] = 33 }.
            to change { subject.age }.to(33)
        end
      end
      describe 'with symbols' do
        it 'returns the value of the named member' do
          expect { subject[:name] = 'Robert' }.
            to change { subject.name }.to('Robert')
          expect { subject[:age] = 33 }.
            to change { subject.age }.to(33)
        end
      end
      describe 'with strings' do
        it 'returns the value of the named member' do
          expect { subject['name'] = 'Robert' }.
            to change { subject.name }.to('Robert')
          expect { subject['age'] = 33 }.
            to change { subject.age }.to(33)
        end
      end        
    end
    
    describe '#==' do
      it { expect(subject == nil).to eq(false) }
      it { expect(subject == []).to eq(false) }
      it { expect(subject == {name: 'Bob', age: 32}).to eq(false) }
      it { expect(subject == subject).to eq(true) }
      it { expect(subject == AttrStructSpec::Alpha.new('Bob', 32)).to eq(true) }
      it { expect(subject == AttrStructSpec::Alpha.new('Alice', 32)).to eq(false) }
      it { expect(subject == AttrStructSpec::Alpha.new('Bob', 33)).to eq(false) }
    end
    
    describe '#!=' do
      it { expect(subject != nil).to eq(true) }
      it { expect(subject != []).to eq(true) }
      it { expect(subject != {name: 'Bob', age: 32}).to eq(true) }
      it { expect(subject != subject).to eq(false) }
      it { expect(subject != AttrStructSpec::Alpha.new('Bob', 32)).to eq(false) }
      it { expect(subject != AttrStructSpec::Alpha.new('Alice', 32)).to eq(true) }
      it { expect(subject != AttrStructSpec::Alpha.new('Bob', 33)).to eq(true) }
    end

    describe 'with no init values' do
      subject { AttrStructSpec::Alpha.new }
      it 'initialized name' do
        expect(subject.name).to eq('John Doe')
      end
      it 'initialized age' do
        expect(subject.age).to eq(0)
      end
    end
  end

  describe 'subclassing' do
    describe 'with a duplicate attribute' do
      it 'raises an ArgumentError' do
        expect {
          Class.new(AttrStructSpec::Alpha) do
            attributes :ttl, :name
          end
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'subclass' do
    module AttrStructSpec
      class Beta < Alpha
        attributes :ttl, :created
      end
    end

    let(:now) { Time.now }
    subject { AttrStructSpec::Beta.new('Alice', 21, 3600, now) }
    
    it { expect(subject.members).to eq([:name, :age, :ttl, :created]) }
    it { expect(subject).to be_kind_of(AttrStructSpec::Beta) }
    it { expect(subject).to be_kind_of(AttrStructSpec::Alpha) }
    it { expect(subject.members).to eq([:name, :age, :ttl, :created]) }
    it { expect(subject.to_a).to eq(['Alice', 21, 3600, now]) }    
    
    describe '#[]' do
      describe 'with integers' do
        it 'returns each member value in the order members were added' do
          expect(subject[0]).to eq('Alice')
          expect(subject[1]).to eq(21)
          expect(subject[2]).to eq(3600)
          expect(subject[3]).to eq(now)
        end
      end
      describe 'with symbols' do
        it 'returns the value of the named member' do
          expect(subject[:name]).to eq('Alice')
          expect(subject[:age]).to eq(21)
          expect(subject[:ttl]).to eq(3600)
          expect(subject[:created]).to eq(now)
        end
      end
      describe 'with strings' do
        it 'returns the value of the named member' do
          expect(subject['name']).to eq('Alice')
          expect(subject['age']).to eq(21)
          expect(subject['ttl']).to eq(3600)
          expect(subject['created']).to eq(now)
        end
      end        
    end

    describe '#[]=' do
      describe 'with integers' do
        it 'returns each member value in the order members were added' do
          expect { subject[0] = 'Robert' }.
            to change { subject.name }.to('Robert')
          expect { subject[1] = 33 }.
            to change { subject.age }.to(33)
          expect { subject[2] = 1200 }.
            to change { subject.ttl }.to(1200)
          expect { subject[3] = now-1800 }.
            to change { subject.created }.to(now-1800)
        end
      end
      describe 'with symbols' do
        it 'returns the value of the named member' do
          expect { subject[:name] = 'Robert' }.
            to change { subject.name }.to('Robert')
          expect { subject[:age] = 33 }.
            to change { subject.age }.to(33)
          expect { subject[:ttl] = 1200 }.
            to change { subject.ttl }.to(1200)
          expect { subject[:created] = now-1800 }.
            to change { subject.created }.to(now-1800)
        end
      end
      describe 'with strings' do
        it 'returns the value of the named member' do
          expect { subject['name'] = 'Robert' }.
            to change { subject.name }.to('Robert')
          expect { subject['age'] = 33 }.
            to change { subject.age }.to(33)
          expect { subject['ttl'] = 1200 }.
            to change { subject.ttl }.to(1200)
          expect { subject['created'] = now-1800 }.
            to change { subject.created }.to(now-1800)
        end
      end        
    end
    
    describe '#==' do
      it { expect(subject == nil).to eq(false) }
      it { expect(subject == []).to eq(false) }
      it { expect(subject == {name: 'Alice', age: 21}).to eq(false) }
      it { expect(subject == subject).to eq(true) }
      it { expect(subject == AttrStructSpec::Beta.new('Alice', 21, 3600, now)).to eq(true) }
      it { expect(subject == AttrStructSpec::Beta.new('Alice', 32, 3600, now)).to eq(false) }
      it { expect(subject == AttrStructSpec::Beta.new('Bob', 21, 3600, now)).to eq(false) }
    end
    
    describe '#!=' do
      it { expect(subject != nil).to eq(true) }
      it { expect(subject != []).to eq(true) }
      it { expect(subject != {name: 'Bob', age: 32, ttl: 3600, created: now}).to eq(true) }
      it { expect(subject != subject).to eq(false) }
      it { expect(subject != AttrStructSpec::Beta.new('Alice', 21, 3600, now)).to eq(false) }
      it { expect(subject != AttrStructSpec::Beta.new('Alice', 32, 3600, now)).to eq(true) }
      it { expect(subject != AttrStructSpec::Beta.new('Bob', 21, 3600, now)).to eq(true) }
    end
  end

  describe 'adding a new attribute to the superclass' do
    let(:alpha2) do
      Class.new(AttrStructSpec::Alpha) do
        attributes :address
      end
    end
    let(:beta2) do
      Class.new(alpha2) do
        attributes :ttl, :created
      end
    end

    it { expect(alpha2.members).to eq([:name, :age, :address]) }
    it { expect(beta2.members).to eq([:name, :age, :address, :ttl, :created]) }
    
    it 'adds the attributes after the existing attrs' do
      expect { alpha2.send(:attributes, :state, :code) }.
        to change { alpha2.members }.
             to([:name, :age, :address, :state, :code])
    end

    it 'adds the attributes after the super attrs but before local attrs' do
      expect { alpha2.send(:attributes, :state, :code) }.
        to change { beta2.members }.
             to([:name, :age, :address,
                 :state, :code,
                 :ttl, :created])
    end

    describe 'with added attributes' do
      before(:each) do
        alpha2.send(:attributes, :state, :code)
      end

      let(:a) { alpha2.new }
      let(:b) { beta2.new }
      
      it 'adds accessors to all subclasses' do
        expect { a.state = 123 }.to change { a.state }.to(123)
        expect { b.state = 123 }.to change { b.state }.to(123)
      end
      
      it 'updated the indexes' do
        expect { b[5] = 123 }.to change { b.ttl }.to(123)
      end
    end
  end
end
