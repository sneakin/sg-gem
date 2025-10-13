require 'sg/ext'
using SG::Ext

require 'sg/promise'

shared_examples_for SG::Chainable do
  describe 'no chalinks' do
  end

  describe '#and_then' do
  end

  describe '#rescues' do
  end
end

describe SG::Chain do
  it 'works' do
    called = {}
    rescued = {}
    p = SG::Chain.new { called[0] = _1; _1 + _1 }.
      rescues { rescued[0] = _1; 'oops' }.
      and_then { called[1] = _1; _1 + _1 }
    expect(p.accept(123)).to eql(123*4)
    expect(called).to eql({ 0 => 123, 1 => 246 })

    expect(p.reject(123)).to eql('oopsoops')
    expect(called).to eql({ 0 => nil, 1 => 'oops' })
    expect(rescued[0]).to be_kind_of(RuntimeError)
  end
end

describe SG::Promise2 do
  it 'works' do
    x = 0
    # p = SG::PromiseGold.new do |acc, rej|
    #   if x == 1
    #     rej.call(123)
    #   else
    #     acc.call(456)
    #   end
    # end
    p = SG::Promise2.new do |acc|
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
  end
end

describe SG::Promise do
  let(:queue) { Queue.new }
  
  it 'works' do
    called = {}
    rescued = {}
    v = SG::Defer::Value.new
    p = SG::Promise.new(v,
                        lambda { called[0] = _1; _1 + _1 }).
      rescues { rescued[0] = _1; 'oops' }.
      and_then { called[1] = _1; _1 + _1 }
    allow(v).to receive(:wait).and_return(123)
    expect(p.wait).to eql(123*4)
    expect(called).to eql({ 0 => 123, 1 => 246 })

    p.reset!
    allow(v).to receive(:wait).and_raise(RuntimeError.new('v'))
    expect(p.wait).to eql('oopsoops')
    expect(rescued[0]).to be_kind_of(RuntimeError)
    expect(called).to eql({ 0 => nil, 1 => 'oops' })
  end
  
  describe 'no chaining' do
    describe 'accepting a value' do
    end

    describe 'rejecting a value' do
    end
  end
end
