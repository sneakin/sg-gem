require_relative 'value'
require_relative 'missing'

module SG::Defer
  class Proxy < Value
    include Missing
  end
end
