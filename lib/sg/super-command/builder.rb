require 'sg/array-with-eq'
require 'sg/ext'

using SG::Ext

require_relative 'command'

module SG
  class SuperCommand
    class Builder
      attr_accessor :name, :desc, :action, :argdoc

      def initialize name: nil, desc: nil, options: nil, action: nil, argdoc: nil, &cb
        @name = name
        @desc = desc
        @options = nil
        @action = action
        @argdoc = argdoc
        cb.call(self) if cb
      end

      def options &cb
        @options = cb if cb
        @options
      end

      def run &cb
        if cb
          @action = if cb.arity == 1
                      ocb = cb
                      lambda { |_env, args| ocb.call(args) }
                    else
                      cb
                    end
        end
        self
      end
      
      def to_command
        Command.new(name: Array === name ? ArrayWithEq[*name] : name,
                    desc: desc,
                    options: options,
                    argdoc: argdoc,
                    &action)
      end
    end
  end
end
