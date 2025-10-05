require 'sg/io/reactor'

describe SG::IO::Reactor::BasicInput do
  let(:pipe) { IO.pipe }
  
  subject do
    described_class.new(pipe[0]) do
      @called_back = true
    end
  end

  before do
    pipe[1].puts('hello')
  end
  
  it { expect(subject).to be_kind_of(SG::IO::Reactor::Source) }
  it { expect(subject.io).to eq(pipe[0]) }

  it { expect { subject.close }.to change(subject, :closed?).to eql(true) }
  it { expect { subject.close }.to change(subject.io, :closed?).to eql(true) }
  
  describe 'before closing' do
    it 'needs processing' do
      expect(subject.needs_processing?).to be(true)
    end
    
    it 'calls the initializers block' do
      expect { subject.process }.to change { @called_back }
    end

    describe 'in a reactor' do
      let(:reactor) { SG::IO::Reactor.new }

      before do
        reactor.add_input(subject)
      end
      
      it 'calls the initializers block' do
        expect { 2.times { reactor.process(timeout: 1) } }.to change { @called_back }
      end
    end
  end

  describe 'after closing' do
    before do
      subject.io.close
    end
    
    it 'no longer needs processing' do
      expect(subject.needs_processing?).to be(false)
    end
  end
end
