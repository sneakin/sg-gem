require 'sg/ext'
using SG::Ext

require 'sg/defer'

shared_examples_for 'a Defer::Able' do
  it { expect(subject).to be_kind_of(SG::Defer::Waitable) }
  it { expect(subject).to be_kind_of(SG::Defer::Acceptorable) }
  it { expect(subject).to be_kind_of(SG::Defer::Able) }
  it { expect(subject).to be_respond_to(:wait) }
  it { expect(subject).to be_respond_to(:accept) }
  it { expect(subject).to be_respond_to(:reject) }
  it { expect(subject).to be_respond_to(:reset!) }
end

module SG; module Spec; end; end

module SG::Spec::Defer
  # @abstract
  # Uned to create instances of deferred values that get provided values
  # by unknown means when the #push_value method is called.
  class TestState
    def make_instance
    end

    def setup
    end

    def teardown
    end
    
    def push_value v
    end

    def push_error v
    end

    def mock_for_error v
    end
  end

  # Helper for deferred value tests that can use Queue.
  class QueueTest
    attr_reader :queue, :described_class

    def initialize described_class:
        @described_class = described_class
    end
    
    def make_instance
      described_class.new {
        case data = queue.pop
          in [ 'error', err ] then raise(err)
        else data
        end
      }
    end

    def setup
      @queue = Queue.new
    end

    def teardown
    end

    def push_value v; queue.push(v); end

    def push_error v
      push_value([ 'error', v ])
    end

    # todo needed? yes, for an error in the consumer side; not push error
    def mock_for_error v; push_error(v); end
  end
end

shared_examples_for 'a Defer::Value that can defer' do
  |init_args: nil, this_error: nil|
  
  this_error ||= Class.new(RuntimeError)
  
  describe 'before resolve' do
    it { expect(subject).to_not be_ready }
    it { expect(subject).to_not be_rejected }

    describe '#wait' do
      describe 'the producer returns a deferred value' do
        let(:qval) { described_class.new(*init_args) { '456' } }
        let(:src) { described_class.new(*init_args) { qval } }
        subject { described_class.new(*init_args) { src } }
        
        it 'waits on it' do
          allow(src).to receive(:wait).and_return('heyo')
          expect(subject.wait).to eql('heyo')
        end
        it 'never returns a deferred value' do
          expect(subject.wait).to eql('456')
        end

        it { expect { subject.wait }.to change(subject, :ready?).to(true) }
        it { expect { subject.wait }.to_not change(subject, :rejected?).from(false) }
      end

      describe 'the producer returns a deferred error' do
        let(:qval) { described_class.new(*init_args) { raise this_error, 'deferred' } }
        let(:src) { described_class.new(*init_args) { qval } }
        subject { described_class.new(*init_args) { src } }
        
        it 'waits on it' do
          allow(src).to receive(:wait).and_return('heyo')
          expect(subject.wait).to eql('heyo')
        end

        it 'fails with the error' do
          expect { subject.wait }.to raise_error(this_error)
        end

        it { expect { subject.wait rescue nil }.to change(subject, :ready?).to(true) }
        it { expect { subject.wait rescue nil }.to change(subject, :rejected?).to(true) }
      end
    end
  end
end

shared_examples_for 'a Defer::Value' do
  |test_state:, init_args: nil, test_value: 1234, test_result: test_value, this_error: nil|
  
  this_error ||= Class.new(RuntimeError)
  
  describe 'before resolve' do
    it { expect(subject).to_not be_ready }
    it { expect(subject).to_not be_rejected }

    describe '#wait' do
      describe 'the producer raises an error' do
        subject { described_class.new(*init_args) { raise this_error, 'err' } }
        
        it 'fails with the error' do
          expect { subject.wait }.to raise_error(this_error)
        end

        it { expect { subject.wait rescue nil }.to change(subject, :ready?).to(true) }
        it { expect { subject.wait rescue nil }.to change(subject, :rejected?).to(true) }

        it 'stored and reraises the error' do
          ex = subject.wait rescue $!
          expect { subject.wait }.to raise_error(ex)
        end
      end      
      describe 'without data' do
        before do
          state.mock_for_error(this_error)
        end
        
        it { expect { subject.wait }.to raise_error(this_error) }
      end

      describe 'with data' do
        before do
          state.push_value('1234')
        end

        it 'gets the value from the producer' do
          expect(subject.wait).to eql('1234')
        end

        it { expect { subject.wait }.to change(subject, :ready?).to(true) }
        it { expect { subject.wait }.to_not change(subject, :rejected?) }

        it 'stored the value' do
          subject.wait
          state.push_value('789')
          expect(subject.wait).to eql('1234')
        end
      end
    end

    describe '#accept' do
      describe 'with a deferred value' do
        let(:src) { described_class.new(*init_args) { test_value } }
        
        it 'returns a new deferred value that is dependent' do
          expect(subject.accept(src)).to be_kind_of(SG::Defer::Value)
        end
        
        it 'becomes ready' do
          expect { subject.accept(src) }.
            to change(subject, :ready?)
        end
        
        it 'is not rejected' do
          expect { subject.accept(src) }.
            to_not change(subject, :rejected?)
        end
        
        describe 'dependent resolves' do
          it 'returns the value' do
            expect(subject.accept(src).wait).to eql(test_result)
          end
        end
        
        describe 'dependent errors' do
          let(:src) { described_class.new(*init_args) { raise this_error, 'dependent' } }
          
          it 'fails with the error' do
            expect { subject.accept(src).wait }.to raise_error(this_error)
          end
        end
      end

      describe 'regular value' do
        it 'updated the value' do
          subject.accept('boom')
          expect(subject.wait).to eql('boom')
        end

        it 'becomes ready' do
          expect { subject.accept('boom') }.
            to change(subject, :ready?).to(true)
        end
        
        it 'is not rejected' do
          expect { subject.accept('boom') }.
            to_not change(subject, :rejected?)
        end

        it 'returns the value' do
          expect(subject.accept('boom')).to eql('boom')
        end
      end
    end

    describe '#reject' do
      it 'becomes ready' do
        expect { subject.reject('boom') }.
          to change(subject, :ready?).to(true)
      end
      
      it 'becomes rejected' do
        expect { subject.reject('boom') }.
          to change(subject, :rejected?).to(true)
      end
      
      it 'causes #wait to raise the error' do
        subject.reject(this_error.new) rescue $!
        expect { subject.wait }.to raise_error(this_error)
      end

      it 'returns self' do
        expect(subject.reject(this_error.new)).to be(subject)
      end
    end
  end

  describe 'after resolve' do
    before do
      subject.accept(1234)
    end
    
    describe '#wait' do
      it 'returns the value immediately' do
        expect { subject.wait }.
          to change { Time.now }.to be_within(0.001).of(Time.now)
      end
    end
    describe '#accept' do
      it 'raises error' do
        expect { subject.accept(789) }.
          to raise_error(SG::Defer::AlreadyResolved)
      end
    end
    describe '#reject' do
      it 'raises no error' do
        expect { subject.reject('789') }.
          to_not raise_error
      end
    end
  end

  describe 'after reject' do
    before do
      subject.reject(this_error.new)
    end
    describe '#wait' do
      it 'raises the error' do
        expect { subject.wait }.to raise_error(this_error)
      end
    end
    describe '#accept' do
      it 'raises error' do
        expect { subject.accept(789) }.
          to raise_error(SG::Defer::AlreadyResolved)
      end
    end
    describe '#reject' do
      it 'raises no error' do
        expect { subject.reject('789') }.
          to_not raise_error
      end
    end
  end

  describe '#reset!' do
    before do
      subject.reject('123')
    end
    
    it 'is not ready' do
      expect { subject.reset! }.to change(subject, :ready?).to(false)
    end
    
    it 'is not rejected' do
      expect { subject.reset! }.to change(subject, :rejected?).to(false)
    end
    
    it 'produces a new value' do
      subject.reset!
      state.push_value('xyz')
      expect(subject.wait).to eql('xyz')
    end
  end
end
