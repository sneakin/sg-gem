require 'sg/ext'
using SG::Ext

require_relative 'defer'

describe SG::Defer::Threaded do
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
    sync = true
    q = Queue.new
    n = SG::Defer::Threaded.new { q.pop }
    x = SG::Defer::Threaded.new { sleep(1); 50 }
    y = SG::Defer::Threaded.new { sleep(2); n.wait }
    Thread.new do
      sleep 3
      q.push(x + x)
    end
    z = (n + y)
    expect([x.wait, n.wait, y.wait, z.wait]).
      to eql([50, 100, 100, 200])
    t = Time.now
    expect([x.wait, n.wait, y.wait, z.wait]).
      to eql([50, 100, 100, 200])
    expect(Time.now).to be_within(0.0001).of(t)
  end
end
