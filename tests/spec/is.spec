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
        expect(described_class[&meth] === input).to be(result)
      end
      it 'constructed by bracket' do
        expect(described_class[meth] === input).to be(result)
      end
      it 'constructed by #new' do
        expect(described_class.new(&meth) === input).to be(result)
      end
    end
  end

  context 'string method' do
    subject { described_class[&:alpha?] }
    it_behaves_like 'SG::Is::LogicOps'
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
