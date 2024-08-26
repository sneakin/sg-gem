require 'sg/ext'
using SG::Ext

module SG::Fun
  Identity = lambda { |x| x }

  def maker klass
    lambda { |*a, **o, &b| klass.new(*a, **o, &b) }
  end
end
