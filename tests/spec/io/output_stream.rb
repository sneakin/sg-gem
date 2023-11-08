shared_examples 'an output stream' do
  describe '#close' do
    it { expect { subject.close }.to change(subject, :closed?).to(true) }
    it { expect(subject.close).to be(subject) }
  end
  
  describe '#flush' do
    it { expect(subject.flush).to be(subject) }
  end
  
  describe '#write' do
    it { expect(subject.write('Hello')).to be(5) }
  end
  
  describe '#puts' do
    it { expect(subject.puts('Hello', 'world')).to eq(['Hello','world']) }
  end
end
