require 'thread'
require_relative 'value'

module SG::Defer
  class RactorValue < Value
    attr_reader :ractor
    
    def initialize *a, &fn
      @ractor = ::Ractor.new(*a, &fn)
      super() do
        accept(@ractor.take)
      rescue Ractor::RemoteError
        reject($!.cause)
      end
    end

    def << msg
      ractor.send(msg)
    end
  end
end

if $0 == __FILE__
  p = (ARGV[0] || 10).to_i.times.collect { |n|
    SG::Defer::RactorValue.new(n) { sleep(rand(5)); 100 * _1 } }
  puts(SG::Defer.wait_for(p).inspect)
end
