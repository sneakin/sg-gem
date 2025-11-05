require 'sg/ext'
using SG::Ext

require_relative 'defer'
require 'sg/defer/forked'
require_relative 'forked'

describe SG::Defer::Forked do
  describe 'groups' do
    let(:state) { ForkedTest.new(described_class: described_class) }
    subject { state.make_instance }
    
    before do
      state.setup
    end

    after do
      subject.kill!
      state.teardown
    end

    describe 'with a value' do
      before do
        state.push_value(123)
      end
      it_should_behave_like 'a SG::Defer::Forked'
    end
    it_should_behave_like 'a Defer::Able'
    it_should_behave_like('a Defer::Value',
                          test_value: '1234',
                          test_result: "1234",
                          this_error: ForkedTest::Error)
  end
  
  describe 'ls' do
    subject { SG::Defer::Forked.new('ls') }

    it 'works' do
      expect(subject.wait).to eql(IO.popen('ls') { _1.read })
    end

    it_should_behave_like 'a SG::Defer::Forked'
  end

  describe 'cat' do
    subject do
      SG::Defer::Forked.new('cat', child_args: [ 'hello' ]) do
        _1.puts(_2)
        _1.close_write
        _1.read
      end
    end

    it 'works' do
      expect(subject.wait).to eql("hello\n")
    end

    it_should_behave_like 'a SG::Defer::Forked'
  end
end
