require 'sg/ext'
using SG::Ext

require 'sg/promise'

shared_examples_for 'a Chainable' do
  it { expect(subject).to be_kind_of(SG::Chainable) }
  
  describe 'with no args' do
    it { expect(subject.and_then).to be(subject) }
    it { expect(subject.rescues).to be(subject) }
    it { expect(subject.ensure).to be(subject) }
    it { expect(subject.and_tap).to be(subject) }
  end
  describe 'with a block' do
    it { expect(subject.and_then { _1 }).to be_kind_of(SG::Chainable) }
    it { expect(subject.rescues { _1 }).to be_kind_of(SG::Chainable) }
    it { expect(subject.ensure { _1 }).to be_kind_of(SG::Chainable) }
    it { expect(subject.and_tap { _1 }).to be_kind_of(SG::Chainable) }
  end
end

describe SG::Promise do
  describe 'examples using' do
    attr_accessor :x

    describe 'accepted values' do
      let(:p) do
        SG::Promise.new do |acc|
          acc.accept(456)
        end
      end

      it 'works' do
        expect(p.call).to eql(456)
      end

      it 'chains' do
        p2 = p.and_then { _1 + _1 }
        expect(p2.call).to eql(456*2)
      end
      it 'rescues' do
        p2 = p.rescues { _1 + 1000 }.and_then { _1 + _1 }
        expect(p2.call).to eql(456*2)
      end
      it 'taps' do
        n = nil
        p2 = p.and_tap { n = _1 * 100 }.and_then { _1 + _1 }
        expect { expect(p2.call).to eql(456*2) }.to change { n }.to(456*100)
      end

      describe 'deferred values' do
        it 'waits for values' do
          v = SG::Defer::Value.new { 123 }
          p3 = SG::PromisedValue.new(v)
          expect(p3.call).to eql(123)
          p4 = p3.and_then { _1 * _1 }
          expect(p4.call).to eql(123 * 123)
          p5 = p3.rescues { 1000 }.and_then { _1 * _1 }
          expect(p5.call).to eql(123 * 123)
        end

        it 'writes to deferred values' do
          v = SG::Defer::Value.new # { x == 1 ? raise('boom') : 123 }
          p2 = p.rescues { _1 + 1000 }.and_then { _1 + _1 }
          expect(p2.call(v)).to eql(456 + 456)
          expect(v.wait).to eql(456 + 456)
        end
      end

      it 'ensures' do
        fin = 0
        pe = p.ensure { fin += 1; _1 + 1 }.
          and_then { fin += 10; _1 + 10 }.
          rescues { fin += 100; _1 + 100 }
        expect { pe.call }.to change { fin }.by(11)
      end
    end

    describe 'rejected values' do
      let(:p) do
        SG::Promise.new do |acc|
          acc.reject(123)
        end
      end

      it 'works' do
        expect(p.call).to eql(123)
      end

      it 'stops chains' do
        p2 = p.and_then { _1 + _1 }
        expect(p2.call).to eql(123)
      end

      it 'rescues' do
        p2 = p.rescues { _1 + 1000 }.and_then { _1 + _1 }
        expect(p2.call).to eql(1123 * 2)
      end

      it 'taps rejects' do
        n = nil
        p2 = p.and_tap { n = _1 * 100 }.and_then { _1 + _1 }
        expect { expect(p2.call).to eql(123) }.to change { n }.to(123 * 100)
      end

      it 'taps rescues' do
        n = nil
        p2 = p.rescues { _1 }.and_tap { n = _1 * 100 }.and_then { _1 + _1 }
        expect { expect(p2.call).to eql(123*2) }.to change { n }.to(123 * 100)
      end

      describe 'deferred values' do
        it 'waits' do
          v = SG::Defer::Value.new { raise('boom') }
          p3 = SG::PromisedValue.new(v)
          p4 = p3.and_then { _1 * _1 }
          p5 = p3.rescues { 1000 }.and_then { _1 * _1 }
          expect(p5.call).to eql(1000 * 1000)
        end

        it 'writes to deferred values' do
          v = SG::Defer::Value.new # { x == 1 ? raise('boom') : 123 }
          p2 = p.rescues { 1000 }.and_then { _1 + _1 }
          expect(p2.call(v)).to eql(2000)
          expect(v.wait).to eql(2000)
        end
      end

      it 'ensures' do
        v = SG::Defer::Value.new # { x == 1 ? raise('boom') : 123 }
        fin = 0
        pe = p.ensure { fin += 1; _1 + 1 }.
          and_then { fin += 10; _1 + 10 }.
          rescues { fin += 100; _1 + 100 }
        expect { pe.call }.to change { fin }.by(101)
      end
    end
  end

  shared_examples_for 'accepted Promise' do |**opts|
    describe 'that accepts' do
      it { expect(subject.call).to eql(opts.fetch(:accepts)) }
      it { expect { subject.call(1, 2, 3) }.to change { @promise_args } }
      it 'accepts the value with its argument' do
        acceptor = SG::Promise::Acceptor.new
        expect(acceptor).to receive(:accept).with(opts.fetch(:accepts))
        subject.call(acceptor)
      end
    end
  end

  shared_examples_for 'rejecting Promise' do |**opts|
    it { expect(subject.call).to eql(opts.fetch(:rejects)) }
    it { expect { subject.call(1, 2, 3) rescue $! }.to change { @promise_args } }
    it 'rejects the value with its argument' do
      acceptor = SG::Promise::Acceptor.new
      expect(acceptor).to receive(:reject).with(opts.fetch(:rejects))
      subject.call(acceptor)
    end
  end
  
  shared_examples_for 'rejected Promise' do |**opts|
    describe 'that rejects' do
      before do
        @do_reject = true
      end
      it_should_behave_like 'rejecting Promise', **opts
    end
  end
  
  shared_examples_for 'raising Promise' do |**opts|
    it { expect { subject.call }.to raise_error(opts.fetch(:error).class) }
    it { expect { subject.call(1, 2, 3) rescue $! }.to change { @promise_args } }
    it 'rejects the error with its argument' do
      acceptor = SG::Promise::Acceptor.new
      expect(acceptor).to receive(:reject).with(opts.fetch(:error))
      subject.call(acceptor)
    end
  end

  shared_examples_for 'raised Promise' do |**opts|
    describe 'that raises' do
      before do
        @do_raise = true
      end

      it_should_behave_like 'raising Promise', **opts
    end
  end

  shared_examples_for 'rejected raised Promise' do |**opts|
    describe 'that raises' do
      before do
        @do_raise = true
      end
      it_should_behave_like 'rejecting Promise', **opts
    end
  end
  
  shared_examples_for 'rescued Promise' do |**opts|
    describe 'that rejects' do
      before do
        @do_reject = true
      end
      it_should_behave_like 'accepted Promise', accepts: opts.fetch(:rescues)
    end
    
    describe 'that raises' do
      before do
        @do_raise = true
      end
      it_should_behave_like 'accepted Promise', accepts: opts.fetch(:rescues)
    end
  end

  err = RuntimeError.new('boom')
  
  let(:promise) do
    described_class.new do |acc, *args|
      @promise_args = args
      if @do_reject
        acc.reject(-100)
      elsif @do_raise
        raise err
      else
        acc.accept(100)
      end
    end
  end

  subject { promise }
  
  describe 'no links' do
    it_should_behave_like 'a Chainable'
    it_should_behave_like 'accepted Promise', accepts: 100
    it_should_behave_like 'rejected Promise', rejects: -100
    it_should_behave_like 'raised Promise', error: err
  end

  shared_examples_for 'and_then' do |**opts|
    subject do
      promise.and_then { _1 * 2 }
    end
    
    it_should_behave_like 'a Chainable'
    it_should_behave_like 'accepted Promise', accepts: 200
    it_should_behave_like 'rejected Promise', rejects: -100
    it_should_behave_like 'raised Promise', error: err

    describe 'and then' do
      subject do
        promise.and_then { _1 * 2 }.and_then { _1 * 10 }
      end
      it_should_behave_like 'a Chainable'
      it_should_behave_like 'accepted Promise', accepts: 2000
      it_should_behave_like 'rejected Promise', rejects: -100
      it_should_behave_like 'raised Promise', error: err
    end

    describe 'rescues' do
      subject do
        promise.and_then { _1 * 2 }.rescues { 10000 }
      end
      it_should_behave_like 'a Chainable'
      it_should_behave_like 'accepted Promise', accepts: 200
      it_should_behave_like 'rescued Promise', rescues: 10000
    end

    describe 'ensure' do
      subject do
        promise.and_then { _1 * 2 }.
          ensure { x = Numeric === _1 ? _1 : 0; x - 1000 }
      end
      
      it_should_behave_like 'a Chainable'
      it_should_behave_like 'accepted Promise', accepts: -800
      it_should_behave_like 'rejected Promise', rejects: -1100
      it_should_behave_like 'rejected raised Promise', rejects: -1000

      describe 'that itself raises' do
        subject do
          promise.ensure { raise err }
        end

        it_should_behave_like 'raising Promise', error: err
      end
    end
  end

  it_should_behave_like 'and_then'

  describe 'rescues' do
    subject do
      promise.rescues { 10000 }
    end
        
    it_should_behave_like 'a Chainable'
    it_should_behave_like 'accepted Promise', accepts: 100
    it_should_behave_like 'rescued Promise', rescues: 10000

    describe 'no links'
    describe 'and then'
    describe 'rescues'
    describe 'ensure'
    describe 'and_tap'
  end
  
  describe 'ensure'do
    subject do
      promise.ensure { x = Numeric === _1 ? _1 : 0; x - 1000 }
    end
    
    it_should_behave_like 'a Chainable'
    it_should_behave_like 'accepted Promise', accepts: -900
    it_should_behave_like 'rejected Promise', rejects: -1100
    it_should_behave_like 'rejected raised Promise', rejects: -1000

    describe 'that itself raises' do
      subject do
        promise.ensure { raise err }
      end

      it_should_behave_like 'raising Promise', error: err
    end
    
    describe 'no links'
    describe 'and then'
    describe 'rescues'
    describe 'ensure'
    describe 'and_tap'
  end

  describe 'and_tap' do
    subject do
      promise.and_tap { @fin = _1; (Numeric === _1 ? _1 : 0) - 1000 }
    end
    
    it_should_behave_like 'a Chainable'
    it_should_behave_like 'accepted Promise', accepts: 100
    it_should_behave_like 'rejected Promise', rejects: -100
    it_should_behave_like 'raised Promise', error: err

    describe 'that rejects' do
      before do
        @do_reject = true
      end

      it { expect { subject.call }.to change { @fin } }
    end

    describe 'that raises' do
      before do
        @do_raise = true
      end

      it { expect { subject.call rescue $! }.to change { @fin } }
    end

    describe 'that itself raises' do
      subject do
        promise.and_tap { raise err }
      end

      it_should_behave_like 'raising Promise', error: err
    end
    
    xdescribe 'no links'
    xdescribe 'and then'
    xdescribe 'rescues'
    xdescribe 'ensure'
    xdescribe 'and_tap'
  end
end
