require 'sg/terminstry'
require 'sg/ext'
using SG::Ext

# Driver class for scripts that enumerate subcommands from a directory of scripts.
class SG::MetaCommand
  Self = Pathname.new($0).expand_path
  
  attr_reader :bin_path, :commands, :meta_path, :tty

  # @param path The directory containing the scripts.
  # @param meta_path The path to the meta script, $0 , to exclude from the list.
  # @param tty The SG::Terminstry::Terminal for formatting.
  def initialize path, meta_path: Self, tty: SG::Terminstry::Terminals.global
    @bin_path = Pathname.new(path).expand_path
    @meta_path = meta_path
    @tty = tty
  end

  # Enumerates the scripts in @path into a Hash.
  def commands
    @commands ||= Hash[bin_path.glob('*[^~]').
                       select { |p|
                         p.expand_path != meta_path &&
                         !p.directory? &&
                         p.executable?
                       }.collect { |p| [ p.basename.to_s, p ] }]
  end

  # The primary action: dispatches the command or prints a the usage message.
  def run args = ARGV.dup
    cmd = args.shift
    cmd_path = commands.fetch(cmd)
    Process.exec(cmd_path.to_s, *args)
  rescue KeyError
    usage
    unless cmd.blank? || cmd =~ /help/
      puts
      puts("%sUnknown command:%s %s" %
           [ tty.fg('brightred') + tty.bold, tty.normal, cmd ])
      exit(1)
    end
  end

  # Prints a command list to $stdout.
  def usage
    hi = tty.fg('brightcyan') + tty.bold
    normal = tty.normal
    puts("%sUsage:%s %s command [arguments...]" %
         [ hi, normal, meta_path ])
    puts
    puts("%sCommands:%s" % [ hi, normal ])
    [ 'help', *commands.keys ].sort.each do |name|
      puts("  " + name)
    end
  end
end
