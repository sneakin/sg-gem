require 'sg/ext'
using SG::Ext

require 'sg/spec/matchers'
require_relative 'defer'

describe SG::Defer::Value do
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
    n = described_class.new { q.pop }
    x = described_class.new { 50 }
    y = described_class.new { n.wait }
    q.push(30)
    q.push(50)
    z = described_class.new { n.wait + y.wait }
    expect([x.wait, n.wait, y.wait, z.wait]).
      to eql([50, 30, 30, 60])
    expect_clock_at(0, 0.01) do
      [x.wait, n.wait, y.wait, z.wait]
    end
  end

  describe 'initialized without a block' do
    it { expect { described_class.new }.to raise_error(ArgumentError) }
  end
end
