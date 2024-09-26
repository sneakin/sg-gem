require 'sg/ext'
using SG::Ext

class ::Module
  def __auto_loads
    @__auto_loads ||= Hash.new
  end
  
  def const_missing sym
    raise NameError, sym if __auto_loads[sym]
    parts = self.name.split('::')
    parts.shift if %w{ Object Module }.include?(parts[0])
    parts << sym.to_s
    parts.permutate_with([ :downcase, :underscore, :hyphenate, SG::Fun::Nil, :camelize, :upcase ]) do |path|
      path = path.reject(&:nil?)
      require(File.join(*path))
      __auto_loads[sym] = path
      return const_get(sym)
    rescue LoadError
      next
    end
    raise NameError, sym
  end
end
