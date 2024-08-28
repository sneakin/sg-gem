class SG::IO::Reactor
  class Listener < IInput
    def initialize sock, reactor, &cb
      super(sock)
      @reactor = reactor
      @cb = cb || raise(ArgumentError.new('No accept callback block given.'))
    end

    def process
      sock = io.accept
      # todo a stream for #add_err
      cin, cout = @cb.call(sock)
      # fixme Source wrappers
      if cin
        raise RuntimeError.new("Expected a Reactor::IInput") unless IInput === cin
        @reactor.add_input(cin)
      end
      if cout
        raise RuntimeError.new("Expected a Reactor::IOutput") unless IOutput === cout
        @reactor.add_output(cout)
      end
    rescue
      @on_error ? @on_error.call($!) : raise($!)
    end
    
    def on_error &cb
      @on_error = cb
      self
    end
  end
end
