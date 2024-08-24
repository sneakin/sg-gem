require 'io/console'
require_relative 'constants'
require 'sg/ext'

using SG::Ext

module SG::Terminstry
  def self.tty_size
    size = [ ENV['COLUMNS']&.to_i, ENV['LINES']&.to_i ]
    lines, cols = IO.console.winsize rescue nil
    size[0] ||= cols
    size[1] ||= lines
    size
  end
end
