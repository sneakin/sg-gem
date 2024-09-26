module SG::Ext
  refine ::Module do
    def delegate(*methods, to:)
      methods.each do |m|
        module_eval <<-EOT
def #{m}(...)
  self.#{to}.#{m}(...)
end
EOT
      end
    end

    def mattr_accessor *attrs
      attrs.each do |attr|
        module_eval <<-EOT
def self.#{attr}
  @#{attr}
end
def self.#{attr}= v
  @#{attr} = v
end
EOT
      end
    end

    def xinheritable_attr *attrs
      attrs.each do |attr|
        module_eval <<-EOT
module Attributes
  def #{attr}
    nil
  end
  def #{attr}= val
    define_singleton_method(#{attr.inspect}) do
      val
    end
  end
end
extend(Attributes)
EOT
      end
    end

    def const_by_value n
      constants.find { |c| const_get(c) == n }
    end

    def lookup_const name, prefix = self.name
       Object.const_get([ prefix || '', name ].join('::'))
    rescue NameError
      raise if prefix.blank?
      case prefix.scan(/\A(?:(.*)::)?([^:]*)\Z/)
        in [ [ new_prefix, _ ] ] then
          prefix = new_prefix
          retry
      else raise
      end
    end    
  end
end
