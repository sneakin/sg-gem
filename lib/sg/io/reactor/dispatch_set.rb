class SG::IO::Reactor
  class DispatchSet
    attr_reader :ios
    
    def initialize
      @ios = {}
    end

    def add actor, io = actor.io
      raise ArgumentError.new('expected a Source, not %s' % [ actor.class ]) unless Source === actor
      #raise ArgumentError.new('expected an IO, not %s' % [ io.class ]) unless ::IO === io
      @ios[io] = actor
    end

    def delete actor
      io = Source === actor ? actor.io : actor
      @ios.delete(io)
    end

    def process ios
      ios.each do |io|
        cl = @ios[io]
        cl.process if cl
      end if ios

      cleanup_closed
    end

    def cleanup_closed
      @ios.delete_if { |io, _| io.closed? }
      self
    end

    def needs_processing
      @ios.select { |_, actor| actor.needs_processing? }
    end
  end
end
