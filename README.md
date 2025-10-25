# The SemanticGap Ruby Gem

Copyright © 2023-2025 SemanticGap. Licensed under
an MIT license found in {file:COPYING}. All other
rights reserved.

# Usage

## Installation

### System Wide

    gem install sg-gem

### Per Project

To use the last official release:

    bundle add sg-gem

Or to use the latest Git or local copy located a directory above:

    if File.exist?(File.join(File.dirname(__FILE__), '../sg-gem'))
      gem 'sg', path: '../sg-gem'
    else
      gem 'sg', git: 'git@github.com:sneakin/sg-gem.git'
    end


### Development

    cd sg-gem
    bundle install


# Modules

Requiring `sg` will load the auto loader eliminating explicit
requiring, but functionality is divided up into top level
modules under {SG}.

## Core Refinements

Many core classes have been refined. {SG::Ext} is the core
module for these. There may be other {Refinements}.

    require 'sg/ext'
    using SG::Ext

    'hey there'.camelize # => 'HeyThere'

## Packed Structures

    require 'sg/packed_struct'

    class Person
      include SG::AttrStruct
      include SG::PackedStruct
      define_packing([:name, :string],
                     [:age, :uint8])
      init_attr :age, 0
    end

    bin = Person.new(name: 'Alice', age: 32).pack
    alice = Person.unpack(bin)

## Type Converter

    require 'sg/converter'

    SG::Converter.convert('12.3', Float)
    SG::Converter.register(String, Complex) do |s|
      s =~ /([-+]?\d.*),([-+]?\d.*)/ && Complex($1.to_f, $2.to_f)
    end
    SG::Converter.convert('23,45', Complex)

    using SG::Ext
    '12.34,56'.to(Complex)

## Units of measure

    require 'sg/units'
    SG::Units::Foot.new(3.0).to(SG::Units::Meter)
    SG::Units::Gram.new(5) * 3 + SG::Units::Gram.new(10)
    SG::Units::Liter.new(5) / SG::Units::Minute.new(60) * SG::Units::Second.new(10.0)

## Scripts

### SelfHelp

{SG::SelfHelp} extracts comments from a script built around a `case`
to provide useful `--help` output.

    require 'sg/selfhelp'

    # Use `@commands` to start, and `@cmd` for each case..
    # @commands
    case (cmd = ARGV.shift)
    when 'normal' then # @cmd Do normal stuff
      do_normal_stuff
    when 'big' then # @cmd(amount) Does big stuff with an argument
      do_big_stuff
    else SG::SelfHelp.print # <-- the important bit
    end


### SuperCommand

{SG::SuperCommand} provides subcommand dispatch and argument processing
for scripts.

    require 'sg/super-command'

    scmd = SG::SuperCommand.new do |scmd|
      verbose = false

      scmd.options do |o|
        o.banner = 'Has many commands to run.'
        o.on('--verbose') do
          verbose = true
        end
      end

      scmd.add_command('normal') do |c|
        c.desc = 'Does normal stuff.'

        name = 'you'

        c.options do |o|
          o.on('--name NAME') do |v|
            name = v
          end
        end
        c.run do |args|
          puts("Hello #{name}.")
        end
      end
    end

    scmd.run


## More

* Data
    * {SG::AttrStruct} Struct like objects with greater reflection.
    * {SG::HashStruct} Struct like access to {Hash}.
* Computation
    * {SG::Defer} Place holders for future values.
    * {SG::Promise} Method chaining that computes only when called.
* IO
    * {SG::TablePrinter} Print data as a table to the terminal.
    * {SG::IO::Reactor} IO event loop.
    * {SG::Color} RGB, HSL, and VT100 color classes.
    * {SG::Terminstry} Terminal IO and styling.
    * {SG::WebSocket} Connect to and process web sockets.
* Meta help
    * {sg/autoloader} Automatically loads files for missing constants.
    * {SG::Is} Helpers for case statements.
    * {SG::Fun} Useful lone Procs.
    * {SG::SkipUnless} {#skip_when} and {#skip_unless} for conditional method chaining.
