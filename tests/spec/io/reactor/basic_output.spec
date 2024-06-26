require 'sg/io/reactor'

describe SG::IO::Reactor::BasicOutput do
  let(:pipe) { IO.pipe }
  it { expect { described_class.new(pipe[1]) }.to raise_error(ArgumentError) }
  
  describe '#needs_processing?' do
    subject do
      described_class.new(pipe[1], needs_processing: lambda { @needs_processing = 123 }) { :nop }
    end
    
    it 'calls and returns the needs processing callback' do
      expect { subject.needs_processing? }.to change { @needs_processing }.to(123)
    end

    it 'returns the needs processing callback' do
      expect(subject.needs_processing?).to eq(123)
    end
  end
  
  describe '#process' do
    subject do
      described_class.new(pipe[1]) do
        @called = true
      end
    end

    it 'calls the callback' do
      expect { subject.process }.to change { @called }.to(true)
    end
  end
end
