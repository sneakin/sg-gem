require 'sg/ext'
using SG::Ext

require_relative 'defer'
require 'sg/defer/async-task'
require 'sg/spec/matchers'

class AsyncTaskTest
  class Error < RuntimeError; end
  
  attr_reader :pipe, :described_class
  
  def initialize described_class: SG::Defer::AsyncTask
    @described_class = described_class
  end
  
  def setup
    return if @pipe
    @pipe = Async::Queue.new
  end
  
  def teardown
  end

  def make_instance
    setup unless @pipe
    described_class.new(pipe) do |pipe|
      data = pipe.pop # read_nonblock(1024).strip
      case data
      in [ :error, err ] then raise(err)
      in [ :data, payload ] then payload
      end
    end
  end

  def instance
    @instance ||= make_instance
  end
  
  def push_value v
    pipe.push([ :data, v ])
    #pipe[1].puts(v)
    #pipe[1].flush
  end

  def push_error err
    pipe.push([ :error, err ])
  end
  
  def mock_for_error v; push_error(v); end
end

describe SG::Defer::AsyncTask do
  include SG::Spec::Matchers
  
  let(:state) { AsyncTaskTest.new(described_class: described_class) }
  subject { state.instance }
  
  before do
    state.setup
  end

  after do
    state.teardown
  end

  around do |ex|
    Timeout.timeout(6) do
      Async do
        ex.run
      end.wait
    end
  end

  it_should_behave_like 'a Defer::Able'
  it_should_behave_like('a Defer::Value',
                        test_value: '1234',
                        test_result: "1234",
                        this_error: AsyncTaskTest::Error)

  # it_should_behave_like 'a Defer::Value that can defer'

  it 'works with state' do
    state.push_value(123)
    expect(subject.wait).to eql(123)
  end
  it 'errors with state' do
    state.push_error(AsyncTaskTest::Error.new('Grrr'))
    expect { subject.wait }.to raise_error(AsyncTaskTest::Error)
  end

  it 'works' do
    sync = true
    Async do
      q = Queue.new
      n = SG::Defer::AsyncTask.new { q.pop }
      x = SG::Defer::AsyncTask.new { sleep(1); 50 }
      y = SG::Defer::AsyncTask.new { sleep(2); n.wait }
      Async do
        sleep 3
        q.push(x.wait + x.wait)
      end
      z = SG::Defer::AsyncTask.new { (n.wait + y.wait) }
      tasks = [ x, n, y, z ]
      expect_clock_at(3, 0.01) do
        tasks.each(&:start)
        expect(tasks.collect(&:wait)).
          to eql([50, 100, 100, 200])
      end
      expect_clock_at(0, 0.001) do
        expect(tasks.collect(&:wait)).
          to eql([50, 100, 100, 200])
      end
    end.wait
  end
end
