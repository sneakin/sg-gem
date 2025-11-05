require 'sg/ext'
using SG::Ext

require_relative 'defer'
require_relative 'forked'

class ForkedTest
  class Error < RuntimeError; end
  
  attr_reader :pipe, :described_class
  
  def initialize cmd: 'cat', described_class: SG::Defer::Forked
    @cmd = cmd
    @described_class = described_class
  end
  
  def setup
    return if @pipe
    @pipe = IO.pipe
  end
  
  def teardown
    @pipe.each(&:close)
  end

  def make_instance
    raise ArgumentError, cmd unless String === @cmd
    setup unless @pipe
    described_class.new(@cmd, child_args: [ pipe[0] ]) do |io, pipe|
      data = pipe.readline.strip
      case data
      when /ERROR ([^\n]*)/ then raise Error.new($1)
      else io.puts(data); io.close_write; io.read.strip
      end
    end
  end

  def push_value v
    pipe[1].puts(v)
    pipe[1].flush
  end

  def push_error err
    push_value("ERROR #{err}\n")
  end
  
  def mock_for_error v; push_error(v); end
end

shared_examples_for 'a SG::Defer::Forked' do
  it 'cleaned up' do
    expect(subject.pid).to_not be_nil
    subject.wait
    expect { Process.wait(subject.pid, 1) }.to raise_error(Errno::ECHILD)
  end
end
