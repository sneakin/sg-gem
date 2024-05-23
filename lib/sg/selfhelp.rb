require 'sg/terminstry'

module SG
  module SelfHelp
    def self.scan_for_commands
      File.open($0, 'rt') do |src|
        broke = src.each_line do |l|
          break true if l.match?(/\$0 == __FILE__/)
        end
        return [] unless broke

        cmds = []
        src.each_line do |l|
          case l
          when /^\s*when \/(.+)\/ then( # @cmd(\(.*\))?\s*(.*$))/,
               /^\s*when '(.*)' then( # @cmd(\(.*\))?\s*(.*$))/,
               /^\s*when "(.*)" then( # @cmd(\(.*\))?\s*(.*$))/
          then
            cmds << [
              $1,
              $4,
              $3 ? $3.strip[1...-1] : nil
            ]
          end
        end
        return cmds
      end
    end
    
    def self.print
      tty = SG::Terminstry::Terminals.global
      heading = tty.fg(SG::Color::VT100.new(:brightcyan)) + tty.bold + tty.italic
      bold = tty.bold
      normal = tty.normal
      italic = tty.italic
      puts("%sUsage:%s %s command [args...]" % [ heading, normal, $0 ])
      puts
      puts("%sCommands:%s" % [ heading, normal ])
      cmds = scan_for_commands
      cells = cmds.collect do |(cmd, desc, args)|
        has_args = args && !args.empty?
        if has_args
          cmd = cmd + " " + italic + args
        end
        [ cmd, desc,
          cmd.bytesize - (has_args ? italic.bytesize + 1 : 0),
          has_args
        ]
      end
      max_cmd = 2 + cells.max { |a, b| a[2] <=> b[2] }[2]
      fmt = "%%s%%%is%%s  %%s" % [ max_cmd ]
      fmt2 = "%%s%%%is%%s  %%s" % [ 4 + max_cmd ] # factor in that #% counted the escaped bytes
      cells.each do |(cmd, desc, size, has_args)|
        puts((has_args ? fmt2 : fmt) % [ bold, cmd, normal, desc ])
      end
    end
  end
end
