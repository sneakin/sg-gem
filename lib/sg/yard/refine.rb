require 'yard'

module YARD
  module CLI
    class Yardoc < YardoptsCommand
      def all_objects
        Registry.all(:root, :module, :class, :refinelist)
      end
    end
  end

  module CodeObjects
    class RefineList < YARD::CodeObjects::ModuleObject
      attr_reader :refinements
      
      def initialize parent, name
        @refinements = []
        super
        self.docstring = [ 'Refinements:' ]
      end
      
      def << ident
        @refinements << ident
      end
      
      def title
        'Refinements'
      end
    end
  end

  # Handles `refine` by placing the docs under a module
  # and being added to the {RefineList}'s Refinements index.
  class RefineHandler < YARD::Handlers::Ruby::Base
    handles method_call(:refine)
    namespace_only
    
    def process
      # create the ModuleObject to hold the docs.
      name = statement.parameters[0].source
      mod = register ModuleObject.new(namespace, name.gsub(/\A::/, ''))
      mod.docstring = [ YARD::Docstring.parser.parse(<<-EOT, mod, self).to_docstring ]
Refines {#{name}}. Activate with `using #{namespace.path}`.

#{mod.docstring}
EOT
      parse_block(statement.last.last, namespace: mod)
      # add to the list
      page << mod
    end

    def page
      YARD::Registry.at('Refinements') ||
        register(RefineList.new(:root, 'Refinements'))
    end
  end
end
