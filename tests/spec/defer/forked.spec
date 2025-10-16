require 'sg/ext'
using SG::Ext

require_relative 'defer'
require 'sg/defer/forked'

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

describe SG::Defer::Forked do
  describe 'groups' do
    let(:state) { ForkedTest.new(described_class: described_class) }
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
                          test_state: ForkedTest,
                          init_args: [ [ 'echo', '1234' ] ],
                          test_value: '1234',
                          test_result: "1234",
                          this_error: ForkedTest::Error)
  end
  
  describe 'ls' do
    subject { SG::Defer::Forked.new('ls') }

    it 'works' do
      expect(subject.wait).to eql(IO.popen('ls') { _1.read })
    end
  end

  describe 'cat' do
    subject do
      SG::Defer::Forked.new('cat', child_args: [ 'hello' ]) do
        _1.puts(_2)
        _1.close_write
        _1.read
      end
    end

    it 'works' do
      expect(subject.wait).to eql("hello\n")
    end
  end
end
