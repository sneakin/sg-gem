require 'sg/ext'
using SG::Ext

require_relative 'defer'

describe SG::Defer::Proxy do
  include SG::Spec::Matchers
  
  let(:state) { SG::Spec::Defer::QueueTest.new(described_class: described_class) }
  subject { state.make_instance }
  
  before do
    state.setup
  end

  after do
    state.teardown
  end

  it_should_behave_like 'a Defer::Able'
  it_should_behave_like('a Defer::Value')
  it_should_behave_like 'a Defer::Value that can defer'

  it 'works' do
    q = Queue.new
    n = SG::Defer::Proxy.new { q.pop }
    x = SG::Defer::Proxy.new { 50 }
    y = SG::Defer::Proxy.new { n.wait }
    q.push(x + x)
    q.push(50)
    z = (n + y)
    expect([x.wait, n.wait, y.wait, z.wait]).
      to eql([50, 100, 100, 200])
    expect_clock_at(0, 0.001) { [x.wait, n.wait, y.wait, z.wait] }
  end

  describe 'for an array' do
    subject { described_class.new { [ 10, 100, 200 ] } }

    describe 'missing methods' do
      it 'returns deferred value' do
        expect(subject.sort).to be_kind_of(described_class)
      end
      it 'waits on the subject' do
        n = subject.sort
        allow(subject).to receive(:wait).and_return([ 2, 3, 1 ])
        expect(n.wait).to eql([1,2,3])
      end
      it 'waits on any deferred arguments' do
        other = described_class.new { 100 }
        n = subject.include?(other)
        allow(other).to receive(:wait).and_return(100)
        expect(n.wait).to be(true)
      end
    end
  end
  
  describe 'integer values' do
    let(:value) { 100 }
    let(:ovalue) { 20 }
    let(:other) { described_class.new { ovalue } }
    subject { described_class.new { value } }

    %w{+ - * / ** | & ^}.each do |meth|
      describe "\##{meth}" do
        it { expect(subject.send(meth, other)).
          to be_kind_of(described_class) }
        it { expect(subject.send(meth, other).wait).
          to eql(value.send(meth, ovalue)) }

        it { expect(ovalue.send(meth, subject)).
          to be_kind_of(described_class) }
        it { expect(ovalue.send(meth, subject).wait).
          to eql(ovalue.send(meth, value)) }
      end
    end
  end
end
