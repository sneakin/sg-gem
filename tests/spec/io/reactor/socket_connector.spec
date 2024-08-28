require 'sg/io/reactor'

describe SG::IO::Reactor::SocketConnector do
  using SG::Ext
  
  port = 2000 + rand(1000)
  
  subject do
    described_class.new(host: '127.0.0.1', port: port) do |io|
      @connected_to = io
    end.but(SystemCallError) do |ex|
      @connected_to = ex
    end
  end
  
  it { expect(subject).to be_kind_of(SG::IO::Reactor::Sink) }
  
  describe 'connection happens' do
    let(:reactor) { SG::IO::Reactor.new }
    let(:server) { TCPServer.new(port).tap { |s| s.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1); s.listen(1) } }
    let(:clients) { [] }
    
    before do
      reactor.add_output(subject)
      reactor.add_listener(server) do |client|
        clients << client
        nil
      end
    end

    after do
      server.close
      clients.each(&:close)
    end
    
    describe 'before connecting' do
      it 'needs processing' do
        expect(subject.needs_processing?).to be(true)
      end
    end

    describe 'after connecting' do
      before do
        3.times { reactor.process(timeout: 1) }
      end
      
      it 'calls the initializer block when the socket connects' do
        expect(@connected_to).to be_kind_of(Socket)
      end

      it 'no longer needs processing' do
        expect(subject.needs_processing?).to be(false)
      end
    end
  end

  describe 'connection error occurs' do
    describe 'with an error handling callback' do
      it 'raises an error via callback' do
        expect { 2.times { subject.process } }.to change { @connected_to }.to be_kind_of(Errno::ECONNREFUSED)
      end

      it 'caught the error' do
        expect { subject.process }.to_not raise_error
      end
    end

    describe 'without the error callback' do
      subject do
        described_class.new(host: 'localhost', port: port) do |io|
          @connected_to = io
        end

        it 'raises the error' do
          expect { subject.process }.to raise_error(Errno::ECONNREFUSED)
        end
      end
    end
  end
end
