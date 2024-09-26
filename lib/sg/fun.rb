require 'sg/ext'
using SG::Ext

module SG::Fun
  Identity = lambda { |x| x }
  Nil = lambda { |*,**,&| nil }
  
  def self.maker klass
    lambda { |*a, **o, &b| klass.new(*a, **o, &b) }
  end

  def self.digger *attrs
    lambda { |x| x.dig(*attrs) }
  end

  def self.picker *attrs
    lambda { |x| x.pick(*attrs) }
  end

  def self.attr_picker *attrs
    lambda { |x| x.pick_attrs(*attrs) }
  end

  def self.plucker *attrs
    lambda { |x| x.pluck(*attrs) }
  end
end
