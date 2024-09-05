#!/usr/bin/env -S ruby -W:no-experimental
require 'bundler/setup'
require 'optparse'
require 'sg/terminstry'
require 'sg/table-printer'
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
    
    def initialize default: 'help', tty: SG::Terminstry::Terminals.global, &block
      @commands = Assoc.new(key: :name)
      @default_command = default
      @tty = tty
      @before = []
      @after = []
      add_default_commands
      block.call(self) if block
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
          o.banner = '' # OP provides one that is a problem later..
          o.on('-h', '--help', "Prints out available commands and options.") do
            @help = true
          end
        end
        @options_builder.call(op)
        op.banner = <<-EOT % [ op.program_name, op.banner.blank? ? '' : ("\n\n" + op.banner) ]
#{h}Usage:#{n} %s command [options...]%s

#{h}Global options:#{n}
EOT
        op
      end
    end

    def options_for cmd, opts = options, name: cmd.printable_name
      tty_styles => { heading: h, normal: n }
      global_banner = opts.banner
      if cmd.has_options?
        opts.separator ''
        opts.separator "#{h}Command options:#{n}"
        cmd.build_options(opts)
      end

      banner = opts.banner
      opts.banner = <<-EOT % [ opts.program_name, name, cmd.argdoc != '' ? ' ' : '', cmd.argdoc || '[arguments...]' ]
#{h}Usage:#{n} %s %s [options...]%s%s
EOT
      if cmd.desc
        opts.banner += "\n" + cmd.desc
      end
      if banner != global_banner && !banner.blank?
        opts.banner += "\n" + banner
      end
      
      opts.banner += "\n\n#{h}Global options:#{n}"
      
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
        run_callbacks(@before) unless cmd.name == 'help'
        cmd.call(env, rest)
        run_callbacks(@after) unless cmd.name == 'help'
      end
    end

    def add_command name = nil, obj = nil, &fn
      obj = Builder.new(name: name, &fn).to_command if fn && !obj
      @commands << obj
      self
    end

    def before &cb
      @before << cb
    end
    
    def after &cb
      @after << cb
    end
    
    def print_help cmd_name
      tty_styles => { heading: h, normal: r, bold: b }

      if cmd_name.blank?
        puts(options.help)
        puts
        puts("#{h}Commands#{r}")
        SG::TablePrinter.new(style: :none).
          add_column(align: :right, strategy: :fitted).
          add_column.
          print(commands.collect { |c| [ c.printable_name, c.desc ] },
                width: nil)
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
    
    def run_callbacks arr
      arr.each { |cb| cb.call }
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
    def argdoc
      "alpha beta"
    end
    
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
    c.argdoc = ''
    c.desc = 'Print a number'
    c.run do |env, args|
      case env.command
      when 'one', '1' then puts(1)
      when 'two', '2' then puts(2)
      else puts('many')
      end
    end
  end

  scmd.before do
    puts("Hello!")
  end
  
  scmd.after do
    puts("Bye.")
  end
    
  scmd.run()
end
