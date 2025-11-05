require 'sg/ext'
using SG::Ext

require 'sg/spec/matchers'
require_relative 'defer'
require 'sg/defer/ractor-value'

class RactorValueTest
  class Error < RuntimeError; end
  
  attr_reader :pipe, :described_class
  
  def initialize described_class: SG::Defer::RactorValue
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
    described_class.new do
      data = Ractor.receive
      case data
        in [ :error, err ] then raise Error.new(err)
        in [ :data, data ] then  data
      end
    end
  end

  def instance
    @instance ||= make_instance
  end
    
  def push_value v
    instance << [ :data, v ]
    self
  rescue Ractor::ClosedError
    self
  end

  def push_error err
    instance << [ :error, err ]
    self
  rescue Ractor::ClosedError
    self
  end

  def mock_for_error v; push_error(v); end
end

describe SG::Defer::RactorValue do
  include SG::Spec::Matchers
  
  let(:state) { RactorValueTest.new(described_class: described_class) }
  subject { state.instance }
  
  before do
    state.setup
  end

  after do
    state.teardown
  end
  
  it_should_behave_like 'a Defer::Able'
  it_should_behave_like('a Defer::Value',
                        this_error: RactorValueTest::Error)
  
  it 'works' do
    # would do inter-dependencies but there is NO shared state.
    x = 5.times.collect { |a|
      SG::Defer::RactorValue.new(a) { |n| sleep(n / 2.0); n * 2 } }
    expect_clock_at(2, 0.01) do
      expect(x.collect(&:wait)).to eql([ 0, 2, 4, 6, 8 ])
    end
    expect_clock_at(0, 0.0001) do
      expect(x.collect(&:wait)).to eql([ 0, 2, 4, 6, 8 ])
    end
  end
end
