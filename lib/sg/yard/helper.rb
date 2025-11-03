module SG
  module Yard
    module Helper
      def options_param_hash opts
        # AST nodes like:
        # (:assoc,
        #    s(:label, "to"),
        #    s(:symbol_literal, s(:symbol, s(:ident, "test_fn"))))
        Hash[opts.reject { _1[0].nil? || _1[1].nil? }.
             collect { [ strip_symbol(_1[0].source).to_sym,
                         strip_symbol(_1[1].source)
                       ] }]
      end

      def strip_symbol str
        case str
        when /\A:.*:\Z/ then str[1..-1]
        when /:\Z/  then str[0..-2]
        when /\A:/ then str[1..-1]
        when /\A['"]/ then str[1..-2]
        else str
        end
      end
    end
  end
end
