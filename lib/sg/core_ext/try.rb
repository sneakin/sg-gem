class Object
  def try(m, ...)
    send(m, ...)
  end
end

class NilClass
  def try(m, ...)
    nil
  end
end
