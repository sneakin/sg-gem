require 'sg/ext'
using SG::Ext

require_relative 'defer'

describe SG::Defer::Value do
  it_should_behave_like 'a Defer::Able'
  it_should_behave_like 'a Defer::Value'

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
    t = Time.now
    expect { [x.wait, n.wait, y.wait, z.wait] }.
      to change { Time.now }.to be_within(0.001).of(t)
  end

  describe 'initialized without a block' do
    subject { described_class.new }
    it 'waits for #ready?' do
      Thread.new { sleep(1); subject.accept(100) }
      t = Time.now
      expect { subject.wait }.
        to change { Time.now }.to be_within(2).of(t)
    end
  end
end
