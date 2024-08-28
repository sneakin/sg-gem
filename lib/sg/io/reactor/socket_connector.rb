require 'socket'
require 'sg/ext'
require 'sg/io/reactor'

class SG::IO::Reactor
  using SG::Ext
  
  class SocketConnector < SG::IO::Reactor::Sink
    def initialize family: Socket::AF_INET, protocol: Socket::SOCK_STREAM, host:, port:, &cb
      @cb = cb
      @connected = false
      super(Socket.new(family, protocol, 0))
      @peeraddr = Socket.sockaddr_in(port, host)
    end

    def but *ex, &block
      @cb = @cb.but(*ex, &block)
      self
    end
    
    def needs_processing?
      !@connected
    end
    
    def process
      # verify that the connection was made
      io.connect_nonblock(@peeraddr)
    rescue IO::WaitWritable
    rescue Errno::EISCONN
      @connected = true
      @cb.call(io)
    rescue
      if @cb.on_error
        @cb.on_error.call($!)
      else
        raise
      end
    end
    
    def self.tcp host, port, &cb
      new(family: Socket::AF_INET, protocol: Socket::SOCK_STREAM,
          host: host, port: port, &cb)
    end
    def self.udp host, port, &cb
      new(family: Socket::AF_INET, protocol: Socket::SOCK_DATAGRAM,
          host: host, port: port, &cb)
    end

    def self.tcp6 host, port, &cb
      new(family: Socket::AF_INET6, protocol: Socket::SOCK_STREAM,
          host: host, port: port, &cb)
    end
    def self.udp6 host, port, &cb
      new(family: Socket::AF_INET6, protocol: Socket::SOCK_DATAGRAM,
          host: host, port: port, &cb)
    end
  end
end
