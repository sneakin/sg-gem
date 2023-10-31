require 'io/console'
require_relative 'constants'

module SG::Terminstry
  def self.tty_size
    raise 'haha' if ENV['TTYSIZE'] == '1'
    lines, cols = IO.console.winsize
    [ cols, lines ]
  rescue
    [ ENV.fetch('COLUMNS', 80).to_i, ENV.fetch('LINES', 24).to_i ]
  end
end
