module SG::Ext::Nil
  def try meth = nil, *args, **opts, &block
    nil
  end

  def blank?; true; end

  def to_bool; false; end
end
