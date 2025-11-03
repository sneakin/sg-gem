require 'yard'
require 'sg/yard/helper'

module YARD
  class PredicateHandler < YARD::Handlers::Ruby::Base
    include SG::Yard::Helper
    
    handles method_call(:predicate)
    namespace_only

    # @todo Any comment near a predicate call will document all the added methods, not just the accessor.
    
    def process
      return if statement.type == :var_ref || statement.type == :vcall
      params = statement.parameters(false).dup
      opts = options_param_hash(params.pop)
      read_only = opts[:read_only] == "true"
      
      call_params.each do |p|
        $stderr.puts("Predicate", p, namespace.meths.collect(&:name).inspect)
        o = MethodObject.new(namespace, "#{p}?", scope)
        o.docstring = <<-EOT
@!method #{p}?
Get the @#{p} instance variable as true or false.
@return [Boolean]
EOT
        register(o)

        o = namespace.child(name: "#{p}?", scope: scope)
        $stderr.puts(p, o.inspect)

        unless read_only
          o = MethodObject.new(namespace, "#{p}!", scope)
          o.parameters = [['value', true]]
          o.docstring = <<-EOT
@!method #{p}!(value)
Set the #{p} instance variable backing {#{p}?}.
@param value [Object] The new value.
@return [self]
EOT
          register(o)

          o = MethodObject.new(namespace, "un#{p}!", scope)
          o.docstring = <<-EOT
@!method un#{p}!
Falsify the {#{p}?} predicate.
@return [self]
EOT
          register(o)
        end
      end
    end
  end
end
