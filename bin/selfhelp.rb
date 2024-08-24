#!/usr/bin/env -S ruby -W:no-experimental
# -*-ruby-*-

require 'sg/selfhelp'

if $0 == __FILE__
  case ARGV.shift
    when 'foo' then # @cmd(times) prints foo
      ARGV[0].to_i.times { puts('Foo') }
    when /^bar/ then # @cmd prints bar
      puts('bar')
    when /^fiz(z*)/ then # @cmd prints fizz
      puts('fiz' + $1)
    else SG::SelfHelp.print
  end
end
