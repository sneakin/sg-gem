require 'sg/constants'

require 'sg/ext'
using SG::Ext

module SG
  module IO
  end
end

require 'sg/io/multiplexer'
require 'sg/io/reactor/source'
require 'sg/io/reactor/sink'
require 'sg/io/reactor/basic_input'
require 'sg/io/reactor/basic_output'
require 'sg/io/reactor/queued_output'
require 'sg/io/reactor/listener'
require 'sg/io/reactor/socket_connector'
require 'sg/io/reactor/dispatch_set'

class SG::IO::Reactor
  attr_reader :inputs, :outputs, :errs, :idlers

  inheritable_attr :current
  
  def initialize
    @inputs = DispatchSet.new
    @outputs = DispatchSet.new
    @errs = DispatchSet.new
    @idlers = []
    @done = false
  end

  def << actor
    case actor
    when Source then add_input(actor)
    when Sink then add_output(actor)
    else raise ArgumentError.new("Only Source and Sink subclasses allowed")
    end
  end
  
  def delete actor
    del_input(actor)
    del_output(actor)
    del_err(actor)
    self
  end

  protected  
  def add_to_set set, actor_or_io, io, actor_kind, &cb
    if actor_or_io && cb
      set.add(actor_kind.new(actor_or_io, &cb), actor_or_io)
    elsif actor_or_io
      set.add(actor_or_io, io || actor_or_io.io)
    else
      raise ArgumentError.new("Expected an IO and block, or Actor and IO.")
    end
  end

  public

  def add_input actor_or_io, io = nil, &cb
    add_to_set(@inputs, actor_or_io, io, BasicInput, &cb)
  end

  def del_input actor
    @inputs.delete(actor)
  end

  def add_listener io, &cb
    add_input(Listener.new(io, self, &cb))
  end
  
  def add_output actor, io = nil, &cb
    add_to_set(@outputs, actor, io, BasicOutput, &cb)
  end

  def del_output actor
    @outputs.delete(actor)
  end

  def add_err actor, io = nil, &cb
    add_to_set(@errs, actor, io, BasicInput, &cb)
  end

  def del_err actor
    @errs.delete(actor)
  end

  def add_idler &cb
    @idlers << cb
    cb
  end

  def del_idler fn
    @idlers.delete(fn)
  end

  # @todo error set really is errors and not stderr, possibly every io?
  
  def process timeout: nil
    cleanup_closed
    self.class.current = self
    ios = [ @inputs.needs_processing.keys,
            @outputs.needs_processing.keys,
            @errs.needs_processing.keys
          ]
    i,o,e = ::IO.select(*ios, timeout) unless ios.all?(&:empty?)
    if i || o || e
      @errs.process(e)
      @outputs.process(o)
      @inputs.process(i)
    end
    
    @idlers.each { |i| i.call }
    self
  ensure
    self.class.current = nil
  end

  def flush
    @outputs.cleanup_closed
    i,o,e = ::IO.select([],
                        @outputs.needs_processing.keys,
                        [],
                        0)
    @outputs.process(o) if o
    self
  end

  def cleanup_closed
    @errs.cleanup_closed
    @outputs.cleanup_closed
    @inputs.cleanup_closed
    self
  end
  
  def done!
    flush
    @done = true
  end

  def done?
    @done
  end
  
  def serve! timeout: 60, &cb
    @done = false
    if cb
      until done?
        process(timeout: timeout)
        cb.call
      end
    else
      process(timeout: timeout) until done?
    end
  end
end

