require_relative 'value'
require_relative 'missing'

module SG::Defer
  class Reactor < Value
    include Missing
    def initialize reactor, &fn
      super() do
        reactor.serve! { ready? }
        fn.call
      end
    end
  end
end
