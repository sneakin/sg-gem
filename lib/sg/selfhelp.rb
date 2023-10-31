require 'sg/terminstry'

module SG
  module SelfHelp
    def self.print
      tty = SG::Terminstry::Terminals.global
      heading = tty.fg(SG::Color::VT100.new(:brightcyan)) + tty.bold + tty.italic
      bold = tty.bold
      normal = tty.normal
      puts("%sUsage:%s %s command [args...]" % [ heading, normal, $0 ])
      puts
      puts("%sCommands:%s" % [ heading, normal ])
      File.open($0, 'rt') do |src|
        broke = src.each_line do |l|
          break true if l.match?(/\$0 == __FILE__/)
        end
        exit(-1) unless broke
        cmds = []
        src.each_line do |l|
          case l
          when /^  when \/(.+)\/ then( # (.*$))?/, /^  when '(.*)' then( # (.*$))?/ then
            cmds << [ $1, $3 ]
          end
        end
        cmds.each do |cmd, desc|
          puts("%s%16s%s  %s" % [ bold, cmd, normal, desc ])
        end
      end
    end
  end
end
