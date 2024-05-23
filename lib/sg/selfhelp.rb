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
          when /^\s*when \/(.+)\/ then( # (\(.*\)\s*)?(.*$))?/,
               /^\s*when '(.*)' then( # (\(.*\)\s*)?(.*$))?/,
               /^\s*when "(.*)" then( # (\(.*\)\s*)?(.*$))?/
          then
            cmds << [
              $1,
              $4,
              $3 ? $3.strip[1...-1].split(/\s+/) : []
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
      scan_for_commands.each do |(cmd, desc, args)|
        if args
          cmd = cmd + " " + italic + args.join(' ')
        end
        puts("%s%16s%s  %s" % [ bold, cmd, normal, desc ])
      end
    end
  end
end
