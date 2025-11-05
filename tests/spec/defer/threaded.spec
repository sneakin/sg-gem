require 'sg/ext'
using SG::Ext

require 'sg/spec/matchers'
require_relative 'defer'

describe SG::Defer::Threaded do
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
    expect_clock_at(3, 0.1) do
      expect([x.wait, n.wait, y.wait, z.wait]).
        to eql([50, 100, 100, 200])
    end
    expect_clock_at(0, 0.001) do
      expect([x.wait, n.wait, y.wait, z.wait]).
        to eql([50, 100, 100, 200])
    end
  end
end
