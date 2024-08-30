# coding: utf-8
require 'set'
require 'sg/converter'
require 'sg/ext'

using SG::Ext

module SG::Units
end

require_relative 'units/dimension'
require_relative 'units/unit'
require_relative 'units/transformed-unit'
require_relative 'units/unitless'

require_relative 'units/physics'
require_relative 'units/computing'
require_relative 'units/si'
