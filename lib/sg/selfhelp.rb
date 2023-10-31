module SG
  module SelfHelp
    def self.print
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
          puts("%16s  %s" % [ cmd, desc ])
        end
      end
    end
  end
end
