class SG::RescuedProc < ::Proc
  attr_reader :fn, :on_error, :exceptions
  
  def initialize fn, *exceptions, &cb
    super(&fn)
    @fn = fn
    @exceptions = exceptions
    @on_error = cb
  end

  def call *a, **o, &cb
    @fn.call(*a, **o, &cb)
  rescue
    if @exceptions.empty? || @exceptions.include?($!.class)
      @on_error.call($!)
    else
      raise
    end
  end
end
