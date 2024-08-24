require 'sg/terminstry'
require 'sg/table-printer'
require 'sg/ext'

using SG::Ext

module SG
  module SelfHelp
    def self.scan_for_commands
      File.open($0, 'rt') do |src|
        broke = src.each_line do |l|
          break true if l.match?(/(#\s*@commands|\$0 == __FILE__)/)
        end
        return [] unless broke

        cmds = []
        src.each_line do |l|
          case l
          when /^\s*when '(.*)' then( # @cmd(\(.*\))?\s*(.*$))/,
               /^\s*when "(.*)" then( # @cmd(\(.*\))?\s*(.*$))/
          then
            msg = $4
            args = $3
            cmds << [ $1.split(/['"\/]\s*,\s*['"\/]/).join(', '),
                      msg, args ? args.strip[1...-1] : nil ]
          when /^\s*when \/(.+)\/ then( # @cmd(\(.*\))?\s*(.*$))/ then
            cmds << [ $1, $4, $3 ? $3.strip[1...-1] : nil ]
          end
        end
        return cmds
      end
    end
    
    def self.print io: $stdout, tty: SG::Terminstry::Terminals.global
      heading = tty.fg(SG::Color::VT100.new(:brightcyan)) + tty.bold + tty.italic
      bold = tty.bold
      normal = tty.normal
      italic = tty.italic
      io.puts("%sUsage:%s %s command [args...]" % [ heading, normal, $0 ])
      io.puts
      io.puts("%sCommands:%s" % [ heading, normal ])
      cmds = scan_for_commands
      cells = cmds.collect do |(cmd, desc, args)|
        has_args = !args.blank?
        if has_args
          cmd = "%s %s%s%s" % [ cmd, italic, args, normal ]
        end
        [ cmd, desc,
          cmd.bytesize - (has_args ? italic.bytesize + 1 : 0),
          has_args
        ]
      end
      io.write(normal)
      SG::TablePrinter.new(io: io, style: :none).
        add_column(align: :right, strategy: :fitted, width: 16).
        add_column.
        print(cells.collect { |(cmd, desc, size, has_args)|
                [ "%s%s" % [ bold, cmd ],
                  "%s%s" % [ normal, desc ]
                ]
              })
    end
  end
end
