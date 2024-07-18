require 'sg/ext'

using SG::Ext

module SG
  class SuperCommand
    class Command
      attr_reader :name, :desc, :options, :action, :argdoc
      
      def initialize name:, desc: nil, options: nil, argdoc: nil, &fn
        @name = name
        @desc = desc
        @options = options
        @argdoc = argdoc
        @action = fn
      end

      def call env, args
        action&.call(env, args)
      end

      def has_options?
        !@options.nil?
      end
      
      def build_options opts
        options&.call(opts)
      end

      def printable_name
        case name
        when Regexp then '/' + name.source + '/'
        when Array then '(' + name.join(' | ') + ')'
        else name.to_s
        end
      end
    end
  end
end
