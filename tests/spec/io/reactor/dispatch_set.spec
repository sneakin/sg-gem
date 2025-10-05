require 'sg/io/reactor'

describe SG::IO::Reactor::DispatchSet do
  let(:pipe) { IO.pipe }
  let(:actor) { SG::IO::Reactor::BasicInput.new(pipe[0]) }

  describe '#add' do
    it { expect { subject.add(actor) }.to change(subject, :ios) }
    it { expect { subject.add(actor) }.to change { subject.ios[pipe[0]] } }
  end

  describe '#delete' do
    before do
      subject.add(actor)
    end
    
    it { expect { subject.delete(actor) }.to change { subject.ios[pipe[0]] }.to(nil) }
    it { expect { subject.delete(pipe[0]) }.to change { subject.ios[pipe[0]] }.to(nil) }
    it { expect { subject.delete(SG::IO::Reactor::BasicInput.new(pipe[1])) }.to_not change { subject.ios } }
    it { expect { subject.delete(pipe[1]) }.to_not change { subject.ios } }
  end

  describe 'with mocks' do
    let(:io1) { double('IO', :closed? => false) }
    let(:io2) { double('IO', :closed? => true) }
    let(:mock1) { SG::IO::Reactor::BasicInput.new(io1) }
    let(:mock2) { SG::IO::Reactor::BasicInput.new(io2) }

    before do
      subject.add(mock1)
      subject.add(mock2)
    end
    
    describe '#process' do
      describe 'with no arguments' do
        it 'does not error' do
          expect { subject.process([]) }.to_not raise_error
        end
      end
      
      describe 'with arguments' do
        it 'calls #process on each actor that is associated with the passed IOs' do
          expect(mock1).to receive(:process)
          expect(mock2).to_not receive(:process)
          subject.process([io1])
        end
      end
    end

    describe '#cleanup_closed' do
      it 'deletes any record of closed IOs.' do
        expect { subject.cleanup_closed }.to change { subject.ios[io2] }.to(nil)
      end
    end

    describe '#needs_processing' do
      it 'returns all the IOs that say they need processing' do
        expect(mock1).to receive(:needs_processing?) { true }
        expect(mock2).to receive(:needs_processing?) { false }
        expect(subject.needs_processing).to eq({ io1 => mock1 })
      end
    end
  end
end
