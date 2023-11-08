require 'sg/io/reactor'
require_relative '../output_stream'

describe SG::IO::Reactor::QueuedOutput do
  let(:pipe) { IO.pipe }
  let(:sent) { [] }
  
  subject do
    described_class.new(pipe[1])
  end
  
  it_behaves_like 'an output stream'

  describe 'nothing written' do
    it { expect(subject.needs_processing?).to be(false) }
    it { expect(subject.closed?).to be(false) }
  end

  describe '#process' do
    it { expect { subject.process }.to_not raise_error }
  end

  describe '#write' do
    it 'queues the argument' do
      expect { subject.write('Hello') }.to change(subject, :queue_empty?)
    end

    it 'returns the number of bytes queued' do
      expect(subject.write('hello')).to eq(5)
    end

    describe 'with processing' do
      before do
        subject.write('hello')
        subject.process
      end
      
      it 'wrote the argument as is' do
        expect(pipe[0].read_nonblock(512)).to eq('hello')
      end
    end
  end
  
  describe '#<<' do
    it 'queues the argument' do
      expect { subject << 'Hello' }.to change(subject, :queue_empty?)
    end

    it 'returns the queued output' do
      expect(subject << 'hello').to eq(subject)
    end

    describe 'with processing' do
      before do
        subject << 'hello' << 'world'
        subject.process
      end
      
      it 'wrote the argument as is' do
        expect(pipe[0].read_nonblock(512)).to eq('helloworld')
      end
    end
  end
  
  describe '#puts' do
    describe 'with arguments' do
      it 'queues the arguments joined by newlines' do
        expect { subject.puts('Hello', 'world') }.to change(subject, :queue_empty?)
      end

      it 'returns the queued arguments' do
        expect(subject.puts('hello')).to eq(['hello'])
      end

      describe 'with processing' do
        before do
          subject.puts('hello', 'world', 1234)
          subject.process
        end
        
        it 'wrote the arguments each on a line' do
          expect(pipe[0].read_nonblock(512)).to eq("hello\nworld\n1234\n")
        end
      end
    end

    describe 'without arguments' do
      it 'queued a newline' do
        expect { subject.puts() }.to change(subject, :queue_empty?)
      end

      it 'returns the queued arguments' do
        expect(subject.puts()).to eq([])
      end

      describe 'with processing' do
        before do
          subject.puts()
          subject.process
        end
        
        it 'wrote an empty line' do
          expect(pipe[0].read_nonblock(512)).to eq("\n")
        end
      end
    end
  end
  
  describe 'after a write' do
    before do
      subject.puts("Hello")
    end

    it { expect(subject.needs_processing?).to be(true) }
    it { expect(subject.closed?).to be(false) }

    describe '#process' do
      it { expect { subject.process }.to_not raise_error }
      it { expect { subject.process }.to change(subject, :queue_empty?) }
    end

    describe 'closing before processing' do
      before do
        subject.close
      end
      
      it { expect(subject.needs_processing?).to be(true) }
      it { expect(subject.closed?).to be(true) }
      it { expect(subject.io.closed?).to be(false) }

      describe '#process' do
        it { expect { subject.process }.to_not raise_error }
        it { expect { subject.process }.to change(subject, :queue_empty?) }
        it { expect { subject.process }.to change { subject.io.closed? } }
      end
    end
  end

  describe 'after closing' do
    before do
      subject.close
    end

    it { expect(subject.needs_processing?).to be(false) }
    it { expect(subject.closed?).to be(true) }
    
    describe '#process' do
      it { expect { subject.process }.to_not raise_error }
      it { expect { subject.process }.to change { subject.io.closed? } }
    end
  end

  describe 'with a reactor', slow: true do
    let(:reactor) { SG::IO::Reactor.new }
    before do
      reactor.add_output(subject)
    end

    describe 'before writes' do
      it { expect { reactor.process(timeout: 1) }.to_not raise_error }
      it 'writes nothing' do
        reactor.process(timeout: 1)
        expect { pipe[0].read_nonblock(512) }.to raise_error(Errno::EWOULDBLOCK)
      end
    end

    describe 'after a write' do
      it 'sends queued data' do
        subject.write('hello')
        reactor.process(timeout: 1)
        expect(pipe[0].read_nonblock(512)).to eq('hello')
      end
      
      it 'requeues data that fragments when blocking occurs' do
        # fill the buffer
        nums = (1024*13).times.to_a
        expecting = nums.collect(&:to_s).join("\n") + "\n"
        subject.puts(*nums)
        # write it out
        reactor.process(timeout: 1)
        # read the pipe
        read_data = pipe[0].read_nonblock(1024 * 32)
        expect(read_data).to_not be(nil)
        expect(read_data).to_not eq(expecting)
        expect(subject.queue_empty?).to be(false)

        # send the rest of the data
        reactor.process(timeout: 1)
        # read the rest
        more_data = pipe[0].read_nonblock(1024 * 32)
        expect(more_data).to_not be(nil)
        expect(more_data).to eq(expecting[read_data.size, more_data.size])
        expect(subject.queue_empty?).to be(true)
      end
    end
  end

  describe 'with an intializing block' do
    let(:retval) { nil }
    let(:cb) do
      lambda do |pkt|
        n = pipe[1].write(pkt.upcase)
        retval || n
      end
    end
    
    subject do
      described_class.new(pipe[1], &cb)
    end
    
    it 'calls the block to write the data' do
      subject.puts('hello')
      subject.process
      subject.process
      expect(pipe[0].read_nonblock(512)).to eq("HELLO\n")
    end
    
    describe 'needs the number of bytes written to be returned' do
      let(:retval) { :bugger }
      it 'raises an error' do
        subject.puts('hello')
        expect { subject.process }.to raise_error(ArgumentError)
      end
    end

    describe 'returns less than all bytes' do
      let(:retval) { 3 }
      
      it 'requeues the data after splitting' do
        subject.puts("hello")
        subject.process
        expect(pipe[0].read_nonblock(32)).to eq("HELLO\nLO\n")
      end
    end
  end
end

