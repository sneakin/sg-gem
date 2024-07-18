#!/usr/bin/env ruby
require 'bundler/setup'
require 'optparse'
require 'sg/terminstry'
require 'sg/assoc'
require 'sg/ext'

using SG::Ext

require_relative 'super-command/command'
require_relative 'super-command/builder'

module SG
  class SuperCommand
    Environment = Struct.new(:super_command, :command, :matches)
      
    attr_reader :commands, :options_builder
    attr_accessor :default_command, :tty
    
    def initialize default: 'help', tty: SG::Terminstry::Terminals.global
      @commands = Assoc.new(key: :name)
      @default_command = default
      @tty = tty
      add_default_commands
    end

    def tty_styles
      @tty_styles ||= {
        heading: tty.fg(SG::Color::VT100.new(:brightcyan)) + tty.bold + tty.italic,
        normal: tty.normal,
        bold: tty.bold,
        italic: tty.italic,
        underline: tty.underline
      }
    end
    
    def options op = nil, &cb
      if cb
        @options_builder = cb
      else
        tty_styles => { heading: h, normal: n }
        op ||= OptionParser.new do |o|
          o.banner = <<-EOT % [ o.program_name ]
#{h}Usage:#{n} %s command [options...] [arguments...]

#{h}Global options:#{n}
EOT
          o.on('-h', '--help', "Prints out available commands and options.") do
            @help = true
          end
        end
        @options_builder.call(op)
      end
    end

    def options_for cmd, opts = options, name: cmd.printable_name
      tty_styles => { heading: h, normal: n }
      opts.banner = <<-EOT % [ opts.program_name, name ]
#{h}Usage:#{n} %s %s [options...] [arguments...]
EOT
      if cmd.desc
        opts.banner += "\n" + cmd.desc + "\n"
      end
      
      opts.banner += "\n#{h}Global options:#{n}"

      if cmd.has_options?
        opts.separator ''
        opts.separator "#{h}Command options:#{n}"
        cmd.build_options(opts)
      end
      
      opts      
    end

    def parse_global_options args, opts = options
      mode = nil
      rest = nil
      if args[0]&.start_with?('-')
        rest = opts.order(args)
        mode = rest.shift
      else
        mode = args.shift
        rest = args
      end

      [ mode, opts, rest ]
    end
    
    def run args = ARGV
      @help = false
      mode, opts, rest = parse_global_options(args)
      if @help
        print_help(mode)
        return true
      end
      
      cmd = @commands.fetch(mode) { |_| @commands.fetch(default_command) }
      env = Environment.new(self, mode, @commands.last_match)
      opts = options_for(cmd, opts)
      rest = opts.parse(rest)
      if @help
        print_help(mode)
      else
        cmd.call(env, rest)
      end
    end

    def add_command name = nil, obj = nil, &fn
      obj = Builder.new(name: name, &fn).to_command if fn && !obj
      @commands << obj
      self
    end

    def print_help cmd_name
      tty_styles => { heading: h, normal: r, bold: b }

      if cmd_name.blank?
        puts(options.help)
        puts
        puts("#{h}Commands#{r}")
        tbl = commands.collect { |c| [ c.printable_name, c.desc ] }
        maxw = tbl.max_by { |(n, d)| n.size }&.first&.size || 8
        tbl.each do |(n, d)|
          puts("#{b}%*s#{r}  %s" % [ maxw, n, d ])
        end
      else
        begin
          cmd = Command === cmd_name ? cmd_name : commands.fetch(cmd_name)
          opts = options_for(cmd, name: String === cmd_name ? cmd_name : nil)
          puts(opts.help)
        rescue KeyError
          puts("Unknown command: %s" % [ cmd_name ])
        end
      end
    end
    
    def add_default_commands
      add_command('help') do |cmd|
        cmd.desc = 'Prints this list of commands.'
        cmd.run do |env, args|
          print_help(args[0])
        end
      end
    end
  end
end

if $0 == __FILE__
  scmd = SG::SuperCommand.new
  scmd.options do |o|
    o.on('-v', '--verbose') do
      $verbose = true
    end

    o.on('--version') do
      puts("1.0.0")
      exit
    end
  end

  class OptionCommand < SG::SuperCommand::Command
    def desc
      'Implemented in a class.'
    end
    
    def call env, args
      puts("Option command #{args.inspect}")
      puts("long? #{@long.to_bool}")
      puts("verbose? #{$verbose.to_bool}")
      puts(env.matches.inspect)
    end

    def has_options?
      true
    end
    
    def build_options opts
      opts.on('-l', '--long') do
        @long = true
      end

      opts.separator ''
      opts.separator 'Exercises a command implemented in a class.'
    end
  end
  
  scmd.add_command('options', OptionCommand.new(name: /^opt(ion)?s/))

  scmd.add_command(/more(opt(ion)?s)?/) do |c|
    long = false
    
    c.desc = 'Has many more options.'
    c.run do |env, args|
      puts("Option command #{args.inspect}")
      puts("long? #{long}")
      puts(env.matches.inspect)
    end

    c.options do |o|
      o.on('-l', '--long') do
        long = true
      end
    end
  end    

  scmd.add_command 'zero' do |c|
    c.run do |args|
      puts('0')
    end
  end
  
  scmd.add_command(%w{ one two three } + [ /[-+]?\d+/ ]) do |c|
    c.desc = 'Print a number'
    c.run do |env, args|
      case env.command
      when 'one', '1' then puts(1)
      when 'two', '2' then puts(2)
      else puts('many')
      end
    end
  end
  
  scmd.run()
end
