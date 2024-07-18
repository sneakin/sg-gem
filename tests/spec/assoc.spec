require 'sg/assoc'
require 'sg/ext'

using SG::Ext

describe SG::Assoc do
  describe 'empty' do
    it { expect(subject).to be_empty }
    it { expect(subject).to be_blank }
    it { expect(subject.size).to be(0) }

    it { expect { subject.fetch('hey') }.to raise_error(KeyError) }
    it { expect(subject.fetch('hey', 123)).to be(123) }
    it { expect(subject.fetch('hey') { |k| k == 'hey' ? 1 : 2 }).to be(1) }
    it { expect(subject.fetch('what') { |k| k == 'hey' ? 1 : 2 }).to be(2) }
  end

  describe 'populated' do
    subject { described_class.new(value: lambda { |v| v&.[](1) }) }
    HelloRegexp = /he(l+)(o+)/
    
    before do
      subject <<
        [ HelloRegexp, :hello ] <<
        [ 'boom', :boom ] <<
        [ String, :str ] <<
        [ 1000...2000, :range ]
    end

    it { expect(subject).to_not be_empty }
    it { expect(subject).to_not be_blank }
    it { expect(subject.size).to be(4) }
    
    it { expect(subject['hello']).to be(:hello) }
    it { expect(subject['hellllooo']).to be(:hello) }
    it { expect(subject['hel']).to be(:str) }
    it { expect(subject['boom']).to be(:boom) }
    it { expect(subject['any']).to be(:str) }
    it { expect(subject[123]).to be(nil) }
    it { expect(subject[1234]).to be(:range) }

    it 'stores Regexp match data in @last_match' do
      expect { subject['hello'] }.
        to change(subject, :last_match).
        to eql(HelloRegexp.match('hello'))
      expect { subject['any'] }.
        to change(subject, :last_match).
        to eql(nil)
    end

    it { expect { subject.fetch(:hey) }.to raise_error(KeyError) }
    it { expect(subject.fetch(:hey, 123)).to be(123) }
    it { expect(subject.fetch(:hey) { |k| k == :hey ? 1 : 2 }).to be(1) }
    it { expect(subject.fetch(:what) { |k| k == :hey ? 1 : 2 }).to be(2) }
  end

  describe 'reverse order' do
    subject { described_class.new(value: lambda { |v| v&.[](1) }) }

    before do
      subject <<
        [ 1000...2000, :range ] <<
        [ String, :str ] <<
        [ 'boom', :boom ] <<
        [ /hel+o+/, :hello ]
    end
              
    it { expect(subject).to_not be_empty }
    it { expect(subject).to_not be_blank }
    it { expect(subject.size).to be(4) }
    
    it { expect(subject['hello']).to be(:str) }
    it { expect(subject['hellllooo']).to be(:str) }
    it { expect(subject['hel']).to be(:str) }
    it { expect(subject['boom']).to be(:str) }
    it { expect(subject['any']).to be(:str) }
    it { expect(subject[123]).to be(nil) }
    it { expect(subject[1234]).to be(:range) }

    it 'stores Regexp match data in @last_match' do
      subject.send(:instance_variable_set, '@last_match', 124)
      expect { subject['hello'] }.
        to change(subject, :last_match).
        to eql(nil)
    end

    it { expect { subject.fetch(:hey) }.to raise_error(KeyError) }
    it { expect(subject.fetch(:hey, 123)).to be(123) }    
    it { expect(subject.fetch(:hey) { |k| k == :hey ? 1 : 2 }).to be(1) }
    it { expect(subject.fetch(:what) { |k| k == :hey ? 1 : 2 }).to be(2) }
  end

  describe 'fancier elements' do
    Element = Struct.new(:name, :age)

    before do
      subject <<
        Element.new('Alice', 35) <<
        Element.new('Bob', 64) <<
        Element.new('Cathy', 24)
    end

    [ :name, lambda { |e| e.name } ].each do |key|
      describe "with keys from #{key}" do
        subject { described_class.new(key: key, value: :age) }

        it { expect(subject['Bob']).to be(64) }
        it { expect(subject.fetch('Alice')).to be(35) }
        it { expect(subject.fetch('Dave', 22)).to be(22) }
        it { expect { subject.fetch('Dave') }.to raise_error(KeyError) }
        it { expect(subject.fetch('hey') { |k| k == 'hey' ? 1 : 2 }).to be(1) }
        it { expect(subject.fetch('what') { |k| k == 'hey' ? 1 : 2 }).to be(2) }
      end
    end
  end

  describe 'array builders' do
    subject { described_class.new(%w{ 1 2 3 4 }, key: :to_i, value: :to_s) }
    it { expect(subject.size).to be(4) }
    it { expect(subject[2]).to eql('2') }
  end
end
