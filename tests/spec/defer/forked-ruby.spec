require 'sg/ext'
using SG::Ext

require 'sg/spec/matchers'
require_relative 'defer'
require 'sg/defer/forked'
require_relative 'forked'

class ForkedRubyTest
  class Error < RuntimeError; end
  
  attr_reader :pipe, :described_class
  
  def initialize described_class: SG::Defer::ForkedRuby
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
    setup unless pipe
    described_class.new(pipe[0]) do |pipe|
      n = pipe.read(2).unpack('S').first
      raise 'no data' if n == nil
      bin = pipe.read(n)
      data = Marshal.load(bin)
      case data
        in [ 'error', err ] then raise Error.new(err) # todo test?
      else data
      end
    end
  end

  def push_value v
    bin = Marshal.dump(v)
    pipe[1].write([ bin.bytesize, bin ].pack('SA*'))
    pipe[1].flush
  end

  def push_error err
    push_value([ 'error', err ])
  end

  def mock_for_error v; push_error(v); end
end

describe SG::Defer::ForkedRuby do
  include SG::Spec::Matchers
  
  let(:state) { ForkedRubyTest.new(described_class: described_class) }
  subject { state.make_instance }
  
  before do
    state.setup
  end

  after do
    subject.kill!
    state.teardown
  end
  
  it_should_behave_like 'a Defer::Able'
  it_should_behave_like('a Defer::Value',
                        this_error: SG::Defer::ForkedRuby::Error)
  
  it 'works' do
    # would do inter-dependencies but there is NO shared state.
    x = SG::Defer::ForkedRuby.new { sleep(1); 10 * 2 }
    expect_clock_at(1, 0.01) do
      expect(x.wait).to eql(20)
    end
    expect_clock_at(0, 0.0001) do
      expect(x.wait).to eql(20)
    end
  end

  it 'works in another process' do
    x = SG::Defer::ForkedRuby.new { Process.pid }
    expect(x.wait).to_not eql(Process.pid)
  end

  describe 'with a value' do
    before do
      state.push_value(123)
    end
    it_should_behave_like 'a SG::Defer::Forked'
  end
end
