require 'sg/io/reactor'

describe SG::IO::Reactor::SocketConnector do
  port = 2000 + rand(1000)
  
  describe 'connection happens' do
    let(:reactor) { SG::IO::Reactor.new }
    let(:server) { TCPServer.new(port).tap { |s| s.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1); s.listen(1) } }
    let(:clients) { [] }
    
    let(:client) { described_class.new(host: 'localhost', port: port) { |io| @connected_to = io } }
    
    subject {
      described_class.new(server)do |client|
        clients << client
        nil
      end
    }
    
    before do
      reactor.add_listener(subject)
    end

    after do
      server.close
      clients.each(&:close)
    end
  end
end
