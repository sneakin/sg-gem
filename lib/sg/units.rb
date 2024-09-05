# coding: utf-8
require 'set'
require 'sg/converter'
require 'sg/ext'

using SG::Ext

# Units of measure
#
# @example
#
#     require 'sg/units'
#     SG::Units::Foot.new(3.0).to(SG::Units::Meter)
#     SG::Units::Gram.new(5) * 3 + SG::Units::Gram.new(10)
#     SG::Units::Liter.new(5) / SG::Units::Minute.new(60) * SG::Units::Second.new(10.0)
#
module SG::Units
end

require_relative 'units/dimension'
require_relative 'units/unit'
require_relative 'units/transformed-unit'
require_relative 'units/unitless'

require_relative 'units/physics'
require_relative 'units/computing'
require_relative 'units/si'
