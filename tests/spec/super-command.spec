require 'sg/ext'
using SG::Ext

require 'sg/super-command'

describe SG::SuperCommand do
  SCRIPT = Pathname.new(__FILE__).join(*%w{ .. .. .. lib sg super-command.rb })
  HELP = <<-EOT
Usage: super-command command [options...] [arguments...]

Global options:
    -h, --help                       Prints out available commands and options.
    -v, --verbose
        --version

Commands
                                  help  Prints this list of commands.
                         /^opt(ion)?s/  Implemented in a class.
                   /more(opt(ion)?s)?/  Has many more options.
                                  zero  
(one | two | three | (?-mix:[-+]?\\d+))  Print a number
EOT
  OPTS_HELP = <<-EOT
Usage: super-command %s [options...] [arguments...]

Implemented in a class.

Global options:
    -h, --help                       Prints out available commands and options.
    -v, --verbose
        --version

Command options:
    -l, --long

Exercises a command implemented in a class.
EOT

  def sh cmd, *args
    IO.popen([cmd.to_s, *args.collect(&:to_s)], 'r') do |io|
      io.read
    end
  end

  def ruby script, *args
    sh('ruby', script, *args)
  end

  def super_cmd *args
    ruby(SCRIPT, *args)
  end
  
  describe 'no arguments' do
    subject { sh('ruby', SCRIPT) }
    it { expect(subject).to eql(HELP) }
  end

  describe 'with --help' do
    describe 'and no argument' do
      subject { super_cmd('--help') }
      it { expect(subject).to eql(HELP) }
    end

    describe 'and argument before' do
      subject { super_cmd('options', '--help') }
      it { expect(subject).to eql(OPTS_HELP % [ 'options' ]) }
    end
    
    describe 'and argument after' do
      subject { super_cmd('--help', 'options') }
      it { expect(subject).to eql(OPTS_HELP % [ 'options' ]) }
    end
  end
  
  describe 'help' do
    describe 'with no argument' do
      subject { super_cmd('help') }
      it { expect(subject).to eql(HELP) }
    end

    describe 'with an argument' do
      describe 'that names a command' do
        subject { super_cmd('help', 'opts') }
        it { expect(subject).to eql(OPTS_HELP % [ 'opts' ]) }
      end

      describe 'that names a non-command' do
        subject { super_cmd('help', 'boom') }
        it { expect(subject).to eql("Unknown command: boom\n") }
      end
    end
  end

  describe 'with an unknown command' do
    subject { super_cmd('boom') }
    it { expect(subject).to eql(HELP) }
  end

  describe 'with a command' do
    describe 'provided "-h"' do
      subject { super_cmd('opts', '-h') }
      it { expect(subject).to eql(OPTS_HELP % [ 'opts' ]) }
    end

    describe 'provided "--help"' do
      subject { super_cmd('opts', '--help') }
      it { expect(subject).to eql(OPTS_HELP % [ 'opts' ]) }
    end
    
    describe 'with no arguments' do
      subject { super_cmd('opts') }
      it { expect(subject).to eql(<<-EOT) }
Option command []
long? false
verbose? false
#<MatchData "opts" 1:nil>
EOT
    end

    describe 'with arguments' do
      subject { super_cmd('options', '-l', '-v', 'abc', 'cde') }
      it { expect(subject).to eql(<<-EOT) }
Option command ["abc", "cde"]
long? true
verbose? true
#<MatchData "options" 1:"ion">
EOT
    end
  end

  describe 'with various kinds of matches' do
    describe 'word' do
      subject { super_cmd('zero') }
      it { expect(subject).to eql("0\n") }
    end

    describe 'list' do
      subject { super_cmd('one') }
      it { expect(subject).to eql("1\n") }
    end

    describe 'regexp' do
      %w{ 3 \\-3 }.each do |n|
        describe "to match #{n}" do
          subject { super_cmd(n.to_s) }
          it { expect(subject).to eql("many\n") }
        end
      end
    end
  end
end
