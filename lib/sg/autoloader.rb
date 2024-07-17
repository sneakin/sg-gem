require 'sg/ext'
using SG::Ext

class ::Module
  def const_missing sym
    parts = self.name.split('::')
    parts.shift if parts[0] == 'Object'
    parts << sym.to_s
    begin
      require(File.join(*parts.collect(&:underscore)))
    rescue LoadError
      require(File.join(*parts.collect(&:hyphenate)))
    end
    const_get(sym)
  rescue LoadError
    raise NameError, sym
  end
end
