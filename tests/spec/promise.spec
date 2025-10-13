require 'sg/ext'
using SG::Ext

require 'sg/promise'

shared_examples_for SG::Chainable do
  describe 'no chain links' do
  end

  describe '#and_then' do
  end

  describe '#rescues' do
  end
end

describe SG::Promise do
  it 'works' do
    x = 0
    # p = SG::PromiseGold.new do |acc, rej|
    #   if x == 1
    #     rej.call(123)
    #   else
    #     acc.call(456)
    #   end
    # end
    p = SG::Promise.new do |acc|
      if x == 1
        acc.reject(123)
      else
        acc.accept(456)
      end
    end

    x = 0
    expect(p.call).to eql(456)
    x = 1
    expect(p.call).to eql(123)

    x = 0
    p2 = p.and_then { _1 + _1 }
    expect(p2.call).to eql(456*2)
    x = 1
    expect(p2.call).to eql(123)

    x = 0
    p2 = p.rescues { _1 + 1000 }.and_then { _1 + _1 }
    expect(p2.call).to eql(456*2)
    x = 1
    expect(p2.call).to eql(1123 * 2)

    x = 0
    v = SG::Defer::Value.new { x == 1 ? raise('boom') : 123 }
    p3 = SG::PromisedValue.new(v)
    expect(p3.call).to eql(123)
    p4 = p3.and_then { _1 * _1 }
    expect(p4.call).to eql(123 * 123)
    p5 = p3.rescues { 1000 }.and_then { _1 * _1 }
    expect(p5.call).to eql(123 * 123)
    x = 1
    v.reset!
    expect(p5.call).to eql(1000 * 1000)

    x = 0
    v = SG::Defer::Value.new # { x == 1 ? raise('boom') : 123 }
    #v.reset!
    expect(p2.call(v)).to eql(456 + 456)
    #v.accept(200)
    expect(v.wait).to eql(456 + 456)

    fin = 0
    pe = p.ensure { fin += 1; _1 + 1 }.
      and_then { fin += 10; _1 + 10 }.
      rescues { fin += 100; _1 + 100 }
    x = 0
    expect { pe.call }.to change { fin }.by(11)
    x = 1
    expect { pe.call }.to change { fin }.by(101)

    fin = 0
    pf = p.finally { fin += 1; _1 }.
      and_then { fin += 10; _1 + 10 }.
      rescues { fin += 100; _1 + 100 }
    x = 0
    expect { pf.call }.to change { fin }.by(1)
    x = 1
    expect { pf.call }.to change { fin }.by(1)
  end
end
