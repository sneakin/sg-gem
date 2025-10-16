require 'sg/ext'
using SG::Ext

require_relative 'defer'

describe SG::Defer::Value do
  let(:state) { SG::Spec::Defer::QueueTest.new(described_class: described_class) }
  subject { state.make_instance }
  
  before do
    state.setup
  end

  it_should_behave_like 'a Defer::Able'
  it_should_behave_like('a Defer::Value',
                        test_state: SG::Spec::Defer::QueueTest)
  it_should_behave_like 'a Defer::Value that can defer'
  
  it 'works' do
    q = Queue.new
    n = SG::Defer::Value.new { q.pop }
    x = SG::Defer::Value.new { 50 }
    y = SG::Defer::Value.new { n.wait }
    q.push(30)
    q.push(50)
    z = SG::Defer::Value.new { n.wait + y.wait }
    expect([x.wait, n.wait, y.wait, z.wait]).
      to eql([50, 30, 30, 60])
    t = Time.now.to_f
    expect { [x.wait, n.wait, y.wait, z.wait] }.
      to change { Time.now.to_f }.to be_within(0.01).of(t)
  end

  describe 'initialized without a block' do
    subject { described_class.new }
    it 'waits for #ready?' do
      Thread.new { sleep(1); subject.accept(100) }
      t = Time.now.to_f + 1
      expect { subject.wait }.
        to change { Time.now.to_f }.to be_within(0.001).of(t.to_f)
    end
  end
end
