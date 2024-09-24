require 'sg/ext'
using SG::Ext

class ::Module
  def const_missing sym
    parts = self.name.split('::')
    parts.shift if parts[0] == 'Object'
    parts << sym.to_s
    parts.permutate_with([ :downcase, :upcase, :underscore, :hyphenate, :camelize ]) do |path|
      begin
        require(File.join(*path))
        return const_get(sym)
      rescue LoadError
        next
      end
    end
    raise NameError, sym
  end
end
