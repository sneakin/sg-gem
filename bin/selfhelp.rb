#!/usr/bin/env ruby
require 'sg/selfhelp'

if $0 == __FILE__
  case ARGV.shift
    when 'foo' then # @cmd(times) prints foo
      ARGV[0].to_i.times { puts('Foo') }
    when /^bar/ then # @cmd prints bar
      puts('Foo')
    else SG::SelfHelp.print
  end
end
