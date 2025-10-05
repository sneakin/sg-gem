require 'sg/io/reactor'
require 'sg/io/reactor/line_reader'

describe SG::IO::Reactor::LineReader do
  let(:lines) { [] }
  let(:pipe) { IO.pipe }
  let(:cb) do
    lambda { |l| lines << l }
  end
  
  subject do
    described_class.new(pipe[0], &cb)
  end

  it { expect(subject.io).to eq(pipe[0]) }
  it { expect(subject.needs_processing?).to be(true) }

  it { expect { subject.close }.to change(subject, :closed?).to eql(true) }
  it { expect { subject.close }.to change(subject.io, :closed?).to eql(true) }
  
  describe 'closed IO' do
    before do
      pipe[0].close
    end
    
    it { expect(subject.needs_processing?).to be(false) }
    it { expect(subject.closed?).to be(true) }

    it { expect { subject.process }.to raise_error(IOError) }
  end

  describe 'with stream is at EOF' do
    describe 'with no data' do
      before do
        pipe[1].close
      end
      
      it { expect(subject.needs_processing?).to be(true) }
      it { expect(subject.closed?).to be(false) }

      it 'will call the callback with :eof' do
        expect { subject.process }.to change { lines }.to([ :eof ])
      end
    end

    describe 'with data buffered' do
      before do
        pipe[1].puts('hello', 'world')
        pipe[1].close
      end
      
      it 'will call the callback with the remaining data' do
        expect { subject.process }.to change { lines }.to([ "hello\n", "world\n", :eof ])
      end
    end
  end
  
  describe 'with read size of' do
    [ 8, 16, 128, 1024 ].each do |read_size|
      describe read_size.to_s do
        subject do
          described_class.new(pipe[0], read_size: read_size, &cb)
        end

        it { expect(subject.read_size).to eq(read_size) }
        
        describe 'when a line is smaller than the read size' do
          it 'calls the callback with the line' do
            pipe[1].write('X' * (read_size / 2).ceil + "\n")
            pipe[1].write('Y' * (read_size / 2).ceil + "\n")
            expect { subject.process }.to change { lines.size }
            expect(lines[0]).to eq('X' * (read_size / 2).ceil + "\n")
            expect(lines[1]).to eq('Y' * (read_size / 2).ceil + "\n")
          end
        end

        describe 'when a line is larger than the read size' do
          it 'buffers and waits for the line to complete' do
            pipe[1].write('X' * (read_size * 1.5).ceil)
            expect { subject.process }.to_not change { lines.size }
            pipe[1].write("\n")
            expect { subject.process }.to change { lines.size }
            expect(lines[0]).to eq('X' * (read_size * 1.5).ceil + "\n")
          end
        end
      end
    end
  end
  
  describe 'nondefault separator' do
    [ [ "\n", "hello\nworld", [ "hello\n", "world" ] ],
      [ ":", "hello\nname: bob\nage: 50\n", [ "hello\nname:", " bob\nage:", " 50\n" ] ],
      [ /[:\n]+/, "hello\n\nname: bob\nage: 50\n", [ "hello\n", "\n", "name:", " bob\n", "age:", " 50\n" ] ],
      [ /[:\n ]+/, "hello\n\nname: bob\nage: 50\n", [ "hello\n", "\n", "name:", " ", "bob\n", "age:", " ", "50\n" ] ],
      [ /\n^\w+/, "hello\n\nname: bob\nage: 50\n", [ "hello\n\n", "name: bob\n", "age: 50\n" ] ],
    ].each do |(sep, input, results)|
      describe sep.inspect do
        subject do
          described_class.new(pipe[0], separator: sep, &cb)
        end
        
        it "calls the callback #{results.size} times with parts of #{input.inspect}" do
          pipe[1].write(input)
          pipe[1].close
          subject.process
          expect(lines).to eq(results + [ :eof ])
        end
      end
    end
  end
  
  describe 'with data queued' do
    before do
      pipe[1].puts('hello', 'world')
    end

    it { expect(subject.needs_processing?).to be(true) }
    
    it 'calls the intializer block for each line' do
      expect { subject.process }.to change { lines }.to(["hello\n", "world\n"])
    end
  end

  describe 'in a reactor' do
    let(:reactor) { SG::IO::Reactor.new }

    before do
      reactor.add_input(subject)
      pipe[1].puts('hello', 'world')
    end

    it 'calls the intializer block for each line', slow: true do
      expect { reactor.process(timeout: 1) }.to change { lines }.to(["hello\n", "world\n"])
    end
  end
end
