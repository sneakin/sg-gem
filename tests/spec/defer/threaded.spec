require 'sg/ext'
using SG::Ext

require_relative 'defer'

describe SG::Defer::Value do
  it_should_behave_like 'a Defer::Value'

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
    #q.push(['abc'])
    #y = SG::Defer::Value.new { n.wait + x.wait }
    z = (n + y)
    expect([x.wait, n.wait, y.wait, z.wait]).
      to eql([50, 100, 100, 200])
    t = Time.now
    expect([x.wait, n.wait, y.wait, z.wait]).
      to eql([50, 100, 100, 200])
    expect(Time.now).to be_within(0.0001).of(t)
  end
end
