require 'sg/io/reactor'
require 'socket'
require 'timeout'

# todo defense against IO errors

describe SG::IO::Reactor do
  time_out = 2
  port = 4112
    
  describe 'with inputs' do
    let(:pipe) { IO.pipe }
    let(:input) { pipe[0] }
    let(:output) { pipe[1] }
    
    before do
      @input_actor = subject.add_input(input) do
        @has_input = true
      end
    end
    
    describe '#process', slow: true do
      it "times out" do
        start = Time.now
        expect(subject.process(timeout: time_out)).to be(subject)
        ending = Time.now
        expect(ending - start).to be >= time_out
      end
      
      it "does not call the input's callback" do
        expect { subject.process(timeout: time_out) }.to_not change { @has_input }
      end
      
      describe 'after writing to the output' do
        before do
          output.puts("Halo")
        end
        
        it "calls the input's block" do
          expect { subject.process(timeout: time_out) }.to change { @has_input }
        end
      end
    end

    describe '#del_input' do
      it { expect { subject.del_input(@input_actor) }.to change { subject.inputs.ios } }
      it { expect { subject.del_input(input) }.to change { subject.inputs.ios } }
    end
    
    describe '#delete' do
      it { expect { subject.delete(@input_actor) }.to change { subject.inputs.ios } }
      it { expect { subject.delete(input) }.to change { subject.inputs.ios } }
    end
    
  end
  
  describe 'with outputs' do
    let(:pipe) { IO.pipe }
    let(:input) { pipe[0] }
    let(:output) { pipe[1] }
    let(:needs_processing) { true }
        
    before do
      @output_actor = subject.add_output(SG::IO::Reactor::BasicOutput.new(output, needs_processing: lambda { needs_processing }) do
        @can_output = true
      end)
    end
    
    describe '#process', slow: true do
      it "calls the output's callback" do
        expect { subject.process(timeout: time_out) }.to change { @can_output }
      end
      
      describe 'after filling the output' do
        before do
          begin
            64.times do
              output.write_nonblock("Halo\n" * 1024)
              output.flush
            end
          rescue IO::EAGAINWaitWritable
          end
        end
        
        it "does not call the output's callback" do
          expect { subject.process(timeout: time_out) }.to_not change { @can_output }
        end
      
        it "times out" do
          start = Time.now
          expect(subject.process(timeout: time_out)).to be(subject)
          ending = Time.now
          expect(ending - start).to be >= time_out
        end
      end
    end

    describe '#flush' do
      it "calls the output's callback" do
        expect { subject.flush }.to change { @can_output }
      end
      
      describe 'after filling the output' do
        before do
          begin
            64.times do
              output.write_nonblock("Halo\n" * 1024)
              output.flush
            end
          rescue IO::EAGAINWaitWritable
          end
        end
        
        it "does not call the output's callback" do
          expect { subject.flush }.to_not change { @can_output }
        end
      
        it "times out immediately" do
          start = Time.now
          expect(subject.flush).to be(subject)
          ending = Time.now
          expect(ending - start).to be < 1
        end
      end
    end

    describe '#del_output' do
      it { expect { subject.del_output(@output_actor) }.to change { subject.outputs.ios } }
      it { expect { subject.del_output(output) }.to change { subject.outputs.ios } }
    end

    describe '#delete' do
      it { expect { subject.delete(@output_actor) }.to change { subject.outputs.ios } }
      it { expect { subject.delete(output) }.to change { subject.outputs.ios } }
    end
    
  end

  describe 'with OOB on a TCP socket' do  
    let(:server) { TCPServer.new(port).tap { |s| s.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1); s.listen(1) } }
    let(:worker) { server.accept }
    let(:client) { TCPSocket.new('localhost', port) }
    
    let(:needs_processing) { true }
        
    before do
      expect(server).to_not be_nil
      expect(client).to_not be_nil
      expect(worker).to_not be_nil
      
      @err_actor = subject.add_err(client) do
        @err_input = true
      end
    end
    
    after do
      worker.close
      server.close
    end
    
    describe '#process' do
      it "does not call the error callback" do
        expect { subject.process(timeout: time_out) }.to_not change { @err_input }
      end
      
      it "times out", slow: true do
        start = Time.now
        expect(subject.process(timeout: time_out)).to be(subject)
        ending = Time.now
        expect(ending - start).to be >= time_out
      end

      describe 'after sending data', slow: true do
        before do
          worker.sendmsg("Hello")
        end
        
        it "does not call the error callback" do
          expect { subject.process(timeout: time_out) }.to_not change { @err_input }
        end
      
        it "times out" do
          start = Time.now
          expect(subject.process(timeout: time_out)).to be(subject)
          ending = Time.now
          expect(ending - start).to be >= time_out
        end
      end

      describe 'after sending OOB data' do
        before do
          worker.sendmsg("!", Socket::MSG_OOB)
        end
        
        it "calls the error callback" do
          expect { subject.process(timeout: time_out) }.to change { @err_input }
        end
      end
    end

    describe '#del_err' do
      it { expect { subject.del_err(@err_actor) }.to change { subject.errs.ios } }
      it { expect { subject.del_err(client) }.to change { subject.errs.ios } }
    end

    describe '#delete' do
      it { expect { subject.delete(@err_actor) }.to change { subject.errs.ios } }
      it { expect { subject.delete(client) }.to change { subject.errs.ios } }
    end
  end

  describe 'with an idler' do
    before do
      @idler = subject.add_idler do
        @idled = true
      end
    end
    
    describe '#process', slow: true do
      describe 'with no activity' do
        it 'calls the idler' do
          expect { subject.process(timeout: time_out) }.to change { @idled }
        end
      end

      describe 'with activity' do
        before do
          subject.add_input($stdin) do
            # noop
          end
        end
        
        it 'calls the idler' do
          expect { subject.process(timeout: time_out) }.to change { @idled }
        end
      end
    end

    describe '#del_idler' do
      it { expect { subject.del_idler(@idler) }.to change(subject, :idlers) }
    end
  end

  describe '#done!' do
    it { expect { subject.done! }.to change(subject, :done?).to(true) }
  end
  
  describe '#serve!', slow: true do
    let(:pipe) { IO.pipe }
                         
    before do
      subject.add_input(pipe[0]) do
        @can_read = true
      end
      @done = false
      @cb_calls = 0
      @start = Time.now
      @thread = Thread.new do
        subject.serve!(timeout: 1) do
          @cb_calls += 1
        end
        @done = true
      end
      Thread.pass
    end

    after do
      @thread.kill
    end

    it { expect { subject.done!; Timeout.timeout(5) { @thread.join } }.to change { @thread.alive? }.from(true).to(false) }
    it { expect { subject.done! }.to change { subject.done? }.to(true) }
    it { expect { subject.done!; sleep(2) }.to change { @done }.to(true) }

    it 'calls the block after each processing' do
      expect { sleep(2) }.to change { @cb_calls }.from(0).to be >= 1
    end
    
    it 'uses the supplied timeout' do
      subject.done!
      begin
        Timeout.timeout(5) { @thread.join }
      rescue Timeout::Error
      end
      ending = Time.now
      expect(ending - @start).to be < 2
    end
  end

  describe '#add_listener' do
    let(:server) { TCPServer.new(port).tap { |s| s.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1); s.listen(1) } }

    before do
      server
    end

    after do
      server.close
    end

    it { expect { subject.add_listener(server) }.to raise_error(ArgumentError) }
    it { expect { subject.add_listener(server) { :ok } }.to change { subject.inputs.ios } }
    it { expect(subject.add_listener(server) { :ok }).to be_kind_of(SG::IO::Reactor::Listener) }
  end
end
