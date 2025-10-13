require 'sg/ext'
using SG::Ext

require 'sg/defer'

shared_examples_for 'a Futurable' do
  it { expect(subject).to be_kind_of(SG::Defer::Futurable) }
  it { expect(subject).to be_kind_of(SG::Defer::Rejectable) }
  it { expect(subject).to be_kind_of(SG::Defer::Able) }
  it { expect(subject).to be_respond_to(:wait) }
  it { expect(subject).to be_respond_to(:resolve) }
  it { expect(subject).to be_respond_to(:resolve!) }
  it { expect(subject).to be_respond_to(:failed!) }
  it { expect(subject).to be_respond_to(:reset!) }
end

shared_examples_for 'a Defer::Value' do
  let(:this_error) { Class.new(RuntimeError) }
  let(:queue) { Queue.new } # a data source
  subject { described_class.new { queue.pop } }
  
  describe 'before resolve' do
    it { expect(subject).to_not be_ready }
    it { expect(subject).to_not be_failed }

    describe '#wait' do
      describe 'without data' do
        before do
          allow(queue).to receive(:pop).and_raise(this_error)
        end
        
        it { expect { subject.wait }.to raise_error(this_error) }
      end

      describe 'with data' do
        before do
          queue.push('1234')
        end
        
        it 'gets the value from the producer' do
          expect { expect(subject.wait).to eql('1234') }.
            to change(queue, :size).by(-1)
        end
        it { expect { subject.wait }.to change(subject, :ready?).to(true) }
        it { expect { subject.wait }.to_not change(subject, :failed?) }

        it 'stored the value' do
          subject.wait
          expect { expect(subject.wait).to eql('1234') }.
            to_not change(queue, :size)
        end
      end
      
      describe 'the producer raises an error' do
        subject { described_class.new { raise this_error } }
        
        it 'fails with the error' do
          expect { subject.wait }.to raise_error(this_error)
        end

        it { expect { subject.wait rescue nil }.to change(subject, :ready?).to(true) }
        it { expect { subject.wait rescue nil }.to change(subject, :failed?).to(true) }

        it 'stored and reraises the error' do
          ex = subject.wait rescue $!
          expect { subject.wait }.to raise_error(ex)
        end
      end
      
      describe 'the producer returns a deferred value' do
        let(:qval) { described_class.new { '456' } }
        let(:src) { described_class.new { qval } }
        subject { described_class.new { src } }
        
        it 'waits on it' do
          allow(src).to receive(:wait).and_return('heyo')
          expect(subject.wait).to eql('heyo')
        end
        it 'never returns a deferred value' do
          expect(subject.wait).to eql('456')
        end

        it { expect { subject.wait }.to change(subject, :ready?).to(true) }
        it { expect { subject.wait }.to_not change(subject, :failed?).from(false) }
      end

      describe 'the producer returns a deferred error' do
        let(:qval) { described_class.new { raise this_error } }
        let(:src) { described_class.new { qval } }
        subject { described_class.new { src } }
        
        it 'waits on it' do
          allow(src).to receive(:wait).and_return('heyo')
          expect(subject.wait).to eql('heyo')
        end

        it 'fails with the error' do
          expect { subject.wait }.to raise_error(this_error)
        end

        it { expect { subject.wait rescue nil }.to change(subject, :ready?).to(true) }
        it { expect { subject.wait rescue nil }.to change(subject, :failed?).to(true) }
      end
    end

    describe '#resolve!' do
      describe 'with a deferred value' do
        let(:src) { described_class.new { 1234 } }
        
        it 'returns a new deferred value that is dependent' do
          expect(subject.resolve!(src)).to be_kind_of(described_class)
        end
        
        it 'stays not ready' do
          expect { subject.resolve!(src) }.
            to_not change(subject, :ready?)
        end
        
        it 'is not failed' do
          expect { subject.resolve!(src) }.
            to_not change(subject, :failed?)
        end
        
        describe 'dependent resolves' do
          it 'returns the value' do
            expect(subject.resolve!(src).wait).to eql(1234)
          end
        end
        
        describe 'dependent errors' do
          let(:src) { described_class.new { raise this_error } }
          
          it 'fails with the error' do
            expect { subject.resolve!(src).wait }.to raise_error(this_error)
          end
        end
      end

      describe 'regular value' do
        it 'becomes ready' do
          expect { subject.resolve!('boom') }.
            to change(subject, :ready?).to(true)
        end
        
        it 'is not failed' do
          expect { subject.resolve!('boom') }.
            to_not change(subject, :failed?)
        end

        it 'returns the value' do
          expect(subject.resolve!('boom')).to eql('boom')
        end
      end
    end

    describe '#failed!' do
      it 'becomes ready' do
        expect { subject.failed!('boom') }.
          to change(subject, :ready?).to(true)
      end
      
      it 'becomes failed' do
        expect { subject.failed!('boom') }.
          to change(subject, :failed?).to(true)
      end
      
      it 'causes #wait to raise the error' do
        subject.failed!(this_error.new)
        expect { subject.wait }.to raise_error(this_error)
      end

      it 'returns the value' do
        expect(subject.failed!(1234)).to eql(1234)
      end
    end
  end

  describe 'after resolve' do
    before do
      subject.resolve!(1234)
    end
    
    describe '#wait' do
      it 'returns the value immediately' do
        expect { subject.wait }.
          to change { Time.now }.to be_within(0.001).of(Time.now)
      end
    end
    describe '#resolve!' do
      it 'raises error' do
        expect { subject.resolve!(789) }.
          to raise_error(SG::Defer::AlreadyResolved)
      end
    end
    describe '#fail!' do
      it 'raises error' do
        expect { subject.resolve!(789) }.
          to raise_error(SG::Defer::AlreadyResolved)
      end
    end
  end

  describe 'after fail' do
    before do
      subject.failed!(this_error.new)
    end
    describe '#wait' do
      it 'raises the error' do
        expect { subject.wait }.to raise_error(this_error)
      end
    end
    describe '#resolve!' do
      it 'raises error' do
        expect { subject.resolve!(789) }.
          to raise_error(SG::Defer::AlreadyResolved)
      end
    end
    describe '#fail!' do
      it 'raises error' do
        expect { subject.resolve!(789) }.
          to raise_error(SG::Defer::AlreadyResolved)
      end
    end
  end

  describe '#reset!' do
    before do
      subject.failed!(123)
    end
    
    it 'is not ready' do
      expect { subject.reset! }.to change(subject, :ready?).to(false)
    end
    
    it 'is not failed' do
      expect { subject.reset! }.to change(subject, :failed?).to(false)
    end
    
    it 'produces a new value' do
      subject.reset!
      queue.push(:xyz)
      expect(subject.wait).to eql(:xyz)
    end
  end
end
