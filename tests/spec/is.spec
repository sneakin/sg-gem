require 'sg/ext'
using SG::Ext

require 'sg/is'

shared_examples 'SG::Is::LogicOps' do
  describe '#&' do
    it { expect(subject & subject).to be_kind_of(SG::Is::And) }
  end
  describe '#|' do
    it { expect(subject | subject).to be_kind_of(SG::Is::Or) }
  end
  describe '#~' do
    it { expect(~subject).to be_kind_of(SG::Is::Not) }
  end
  describe '#to_proc' do
    it {
      expect(subject).to receive(:===).with(:other).and_return(:ok)
      expect(subject.to_proc.call(:other)).to be(:ok)
    }
  end
end

describe SG::Is do
  context 'case statement' do
    it 'can be a match' do
      [ [ '123', :digit ],
        [ 'abc', :alpha ],
        [ '!@#', :huh ],
        [ '123abc', :both ]
      ].each do |(input, output)|
        expect(case input
               when SG::Is::Predicated[&:alpha?] then :alpha
               when SG::Is::Predicated[&:digit?] then :digit
               when SG::Is::And[/[[:alpha:]]/, /[[:digit:]]/] then :both
               else :huh
               end).to be(output)
      end
    end
  end
end

# todo arguments to the method
describe SG::Is::Predicated do
  [ [ '123', :digit?, true ],
    [ '123', :alpha?, false ],
    [ 'abc', :alpha?, true ],
    [ 'abc', :digit?, false ],
    [ '!@#', :space?, false ],
    [ '  ', :space?, true ]
  ].each do |(input, meth, result)|
    context "[##{meth}] === #{input.inspect} is #{result}" do
      it 'constructed by bracketed proc' do
        expect(described_class[&meth] === input).to eql(result)
      end
      it 'constructed by bracket' do
        expect(described_class[meth] === input).to eql(result)
      end
      it 'constructed by #new' do
        expect(described_class.new(&meth) === input).to eql(result)
      end
      it 'constructed by #new' do
        expect(described_class.new(meth) === input).to eql(result)
      end
    end
  end

  context 'string method' do
    subject { described_class[&:alpha?] }
    it_behaves_like 'SG::Is::LogicOps'
  end

  [ [ 'abc', :[], [1], 'b' ],
    [ 'abc', :[], [2], 'c' ],
    [ '123', :to_i, [16], 0x123 ],
    [ '123', :to_i, [10], 123 ],
  ].each do |(input, meth, args, result)|
    context "[##{[meth, *args].inspect}] === #{input.inspect} is #{result}" do
      it 'constructed by bracketed proc' do
        expect(described_class[*args, &meth] === input).to eql(result)
      end
      it 'constructed by bracket' do
        expect(described_class[meth, *args] === input).to eql(result)
      end
      it 'constructed by #new' do
        expect(described_class.new(*args, &meth) === input).to eql(result)
      end
      it 'constructed by #new' do
        expect(described_class.new(meth, *args) === input).to eql(result)
      end
    end
  end
end

describe SG::Is::And do
  context 'ranges' do
    subject { described_class[(0...6), (4...10)] }
    it 'matches both' do
      expect(subject === 3).to be(false)
      expect(subject === 4).to be(true)
      expect(subject === 5).to be(true)
      expect(subject === 6).to be(false)
      expect(subject === 7).to be(false)
    end

    it_behaves_like 'SG::Is::LogicOps'
  end

  context 'regex' do
    subject { described_class[/foo/, /bar/] }
    it 'matches only both' do
      expect(subject === 'foobar').to be(true)
      expect(subject === 'foo').to be(false)
      expect(subject === 'bar').to be(false)
      expect(subject === 'hello').to be(false)
    end

    it_behaves_like 'SG::Is::LogicOps'
  end  
end

describe SG::Is::Or do
  context 'ranges' do
    subject { described_class[(0...4), (8...10)] }
    it 'matches either' do
      expect(subject === 3).to be(true)
      expect(subject === 4).to be(false)
      expect(subject === 5).to be(false)
      expect(subject === 6).to be(false)
      expect(subject === 7).to be(false)
      expect(subject === 8).to be(true)
    end

    it_behaves_like 'SG::Is::LogicOps'
  end

  context 'regex' do
    subject { described_class[/foo/, /bar/] }
    it 'matches either' do
      expect(subject === 'foobar').to be(true)
      expect(subject === 'foo').to be(true)
      expect(subject === 'bar').to be(true)
      expect(subject === 'hello').to be(false)
    end

    it_behaves_like 'SG::Is::LogicOps'
  end  
end

describe SG::Is::Not do
  context 'ranges' do
    subject { described_class[(0...4)] }
    it 'matches outside the range' do
      expect(subject === 3).to be(false)
      expect(subject === 4).to be(true)
      expect(subject === 5).to be(true)
    end

    it_behaves_like 'SG::Is::LogicOps'
  end

  context 'regex' do
    subject { described_class[/foo/] }
    it 'matches those that do not match' do
      expect(subject === 'foobar').to be(false)
      expect(subject === 'foo').to be(false)
      expect(subject === 'bar').to be(true)
      expect(subject === 'hello').to be(true)
    end

    it_behaves_like 'SG::Is::LogicOps'
  end  
end

describe SG::Is::Included do
  describe 'with a Class' do
    subject { described_class.new(%w{ alpha }) }
    it_behaves_like 'SG::Is::LogicOps'
  end

  it { expect(described_class[%w{ alpha hello beta }] === 'hello').to be(true) }
  it { expect(described_class[%w{ alpha beta }] === 123).to be(false) }
  it {
    expect([1, :hey, 3.3, 'hello'].select(&described_class[%w{ alpha hello }])).
    to eql(['hello'])
  }
  it {
    expect([1, :hey, 3.3, 'hello'].select(&described_class[[ :hey, 1 ]])).
    to eql([1, :hey])
  }
  it {
    expect([1, :hey, 3.3, 'hello'].select(&described_class[[ 4, 5 ]])).
    to eql([])
  }
end

describe SG::Is::MemberOf do
  describe 'with a Class' do
    subject { described_class.new('alpha') }
    it_behaves_like 'SG::Is::LogicOps'
  end

  it { expect(described_class['hello'] === %w{ alpha hello beta }).to be(true) }
  it { expect(described_class[123] === %w{ alpha beta }).to be(false) }
  it { expect(described_class[3.3] === [1, :hey, 3.3, 'hello']).to be(true) }
end

describe SG::Is::CaseOf do
  describe 'with a Class' do
    subject { described_class.new(String) }
    it_behaves_like 'SG::Is::LogicOps'
  end

  it { expect(described_class[/\w+/] === 'hello').to be(true) }
  it { expect(described_class[/\w+/] === 123).to be(false) }
  it { expect(described_class[String] === 'hello').to be(true) }
  it { expect(described_class[String] === 123).to be(false) }
  it {
    expect([1, :hey, 3.3, 'hello'].select(&described_class[String])).
    to eql(['hello'])
  }
  it {
    expect([1, :hey, 3.3, 'hello'].select(&described_class[Numeric])).
    to eql([1, 3.3])
  }
  it {
    expect([1, :hey, 3.3, 'hello'].select(&described_class[Array])).
    to eql([])
  }
end

describe SG::Is::InCaseOf do
  describe 'with a string' do
    subject { described_class.new('hello') }
    it_behaves_like 'SG::Is::LogicOps'
  end

  it { expect(described_class['hello'] === /\w+/).to be(true) }
  it { expect(described_class[123] === /\w+/).to be(false) }
  it { expect(described_class['hello'] === String).to be(true) }
  it { expect(described_class[123] === String).to be(false) }
  it {
    expect([1, :hey, 3.3, 'hello'].select(&described_class['hello'])).
    to eql(['hello'])
  }
end

describe SG::Is::ResponsiveTo do
  describe 'with a method' do
    subject { described_class.new(:digit?) }
    it_behaves_like 'SG::Is::LogicOps'
  end

  it { expect(described_class[:digit?] === 'hello').to be(true) }
  it { expect(described_class[:digit?] === 123).to be(false) }
  it {
    expect([1, :hey, 3.3, 'hello'].select(&described_class[:upcase])).
    to eql([:hey, 'hello'])
  }
  it {
    expect([1, :hey, 3.3, 'hello'].select(&described_class[:abs])).
    to eql([1, 3.3])
  }
end

