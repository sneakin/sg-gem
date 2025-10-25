require 'yard'
require 'sg/yard/helper'

module YARD
  class DelegateHandler < YARD::Handlers::Ruby::Base
    include SG::Yard::Helper
    
    handles method_call(:delegate)
    namespace_only

    def self.delegate(...); :fakeit; end
    delegate :test1, :test2, to: :test_fn, more: :yes

    def test_fn; :hello; end
    
    def process
      return if statement.type == :var_ref || statement.type == :vcall
      params = statement.parameters(false).dup
      opts = options_param_hash(params.pop)
      meths = params.collect(&:source)
      target = opts.fetch(:to)
      
      # $stderr.puts("Delegating #{meths.inspect} to #{target}", opts.inspect, call_params.inspect)

      meths.each do |m|
        m = strip_symbol(m)
        o = MethodObject.new(namespace, m, scope)
        o.docstring = "Delegated to {%s}." % [ target ]
        register(o)
      end
    end
  end
end
