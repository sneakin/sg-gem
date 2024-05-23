#!/usr/bin/env ruby
require 'sg/selfhelp'

if $0 == __FILE__
  case ARGV.shift
    when 'foo' then # (times) prints foo
      ARGV[0].to_i.times { puts('Foo') }
    when /^bar/ then # prints bar
      puts('Foo')
    else SG::SelfHelp.print
  end
end
