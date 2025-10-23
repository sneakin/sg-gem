require 'benchmark'

require 'sg/ext'
using SG::Ext
require 'sg/is'

module Runs
  module Run
  end
end

require_relative 'packed-struct/std-pack'
require_relative 'packed-struct/bindata'
require_relative 'packed-struct/packed'
require_relative 'packed-struct/ffi-memory'

module Runs
  # todo Other data sources than String IO
  # todo skip write w/ reused static set
  def self.run bm, run, iterations, errs = true
    inst = run.struct(-1)
    io = StringIO.new

    bm.report("#{run.name} write\t")  do
      iterations.times do |n|
        pkt = run.struct(n)
        run.write(pkt, io)
      end
    end

    io.rewind

    bm.report("#{run.name} read\t") do
      iterations.times do |n|
        data = run.read(io)
        #puts data.inspect
        raise "Bad read #{n} #{data.inspect}" if errs && Array === data && data[0].text != 'Hello' && data[0].length != 5
      rescue SG::PackedStruct::NoDataError
        raise "EOF #{n} #{io.pos}"
      end
    end
  end
end

if $0 == __FILE__
  iterations, num_runs = (ENV.fetch('ITERS', '1000,3')).
    split(/\s|,/).collect(&:to_i)
  num_runs = 1 if !num_runs || num_runs <= 0
  profiling = ENV['PROFILE'].to_bool
  
  require 'optparse'
  args = OptParse.new do |o|
    o.on('-i', '--iterations INT', Integer) do
      iterations = _1
    end
    o.on('-r', '--runs INT', Integer) do
      num_runs = _1
    end
    o.on('--profile') do
      profiling = true
    end
  end.parse(ARGV)
  
  runs = args.collect { Runs.const_get(_1).new }
  if runs.empty?
    runs = Runs.constants.
      collect { Runs.const_get(_1) }.
      select(&SG::Is::MemberOf[Runs::Run]). # { Class === _1 && _1.include?(Runs::Run) }.
      collect(&:new)
  end
  # Sanity check for runs writing the same data
  a = b = nil
  runs.combination(2) do
    if (a = _1.write_one) != (b = _2.write_one)
      raise "Mismatch: #{_1.name} #{_2.name}\n#{a.inspect}\n#{b.inspect}"
    end
  end
  # Run!
  require 'profile' if profiling

  num_runs.times do
    Benchmark.bm do |bm|
      runs.each { Runs.run(bm, _1, iterations, Runs::StdPack === _1) }
    end
  end
end
