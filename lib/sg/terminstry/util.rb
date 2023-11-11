require 'io/console'
require_relative 'constants'
require 'sg/ext'

using SG::Ext

module SG::Terminstry
  def self.tty_size
    raise 'haha' if ENV['TTYSIZE'].to_bool
    lines, cols = IO.console.winsize
    [ cols, lines ]
  rescue
    [ ENV.fetch('COLUMNS', 80).to_i, ENV.fetch('LINES', 24).to_i ]
  end
end
