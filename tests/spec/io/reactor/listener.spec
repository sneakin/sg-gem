require 'sg/io/reactor'

describe SG::IO::Reactor::Listener do
  port = 2000 + rand(1000)
  
  describe 'connection happens' do
    let(:reactor) { SG::IO::Reactor.new }
    let(:srv_stream) { instance_double('TCPSocket') }
    let(:in_io) { double('IO') }
    let(:in_stream) { Class.new(SG::IO::Reactor::IInput).new(in_io) }
    let(:out_io) { double('IO') }
    let(:out_stream) { Class.new(SG::IO::Reactor::IOutput).new(out_io) }
    let(:server) { instance_double('TCPServer', accept: srv_stream) }
    let(:clients) { [] }    
    
    subject do
      described_class.new(server, reactor) do |client|
        clients << client
        [ in_stream, out_stream ]
      end
    end
    
    describe '#process' do
      it 'accepts a client' do
        expect(server).to receive(:accept).and_return(srv_stream)
        subject.process
      end

      context 'happy callback' do
        context 'with input and output' do
          it 'adds an input to the reactor' do
            expect { subject.process }.to change(reactor.inputs, :size)
          end
          
          it 'adds an output to the reactor' do
            expect { subject.process }.to change(reactor.outputs, :size)
          end
        end

        xit 'adds an IO exception handler to the reactor'

        context 'with input and no output' do
          let(:out_stream) { nil }
          
          it 'adds an input to the reactor' do
            expect { subject.process }.to change(reactor.inputs, :size)
          end
          
          it 'adds no output to the reactor' do
            expect { subject.process }.to_not change(reactor.outputs, :size)
          end
        end

        context 'with no input and output' do
          let(:in_stream) { nil }
          
          it 'adds no input to the reactor' do
            expect { subject.process }.to_not change(reactor.inputs, :size)
          end
          
          it 'adds an output to the reactor' do
            expect { subject.process }.to change(reactor.outputs, :size)
          end
        end

        context 'with no input and no output' do
          let(:in_stream) { nil }
          let(:out_stream) { nil }
          
          it 'adds no input to the reactor' do
            expect { subject.process }.to_not change(reactor, :inputs)
          end
          
          it 'adds no output to the reactor' do
            expect { subject.process }.to_not change(reactor, :outputs)
          end
        end
      end
      
      context 'a bad listener block' do
        context 'bad input' do
          let(:in_stream) { 'hello' }
          it 'raises an error when the input is not an IInput' do
            expect { subject.process }.to raise_error(RuntimeError)
          end
        end

        context 'bad output' do        
          let(:out_stream) { 'hello' }
          it 'raises an error when the output is not an IOutput' do
            expect { subject.process }.to raise_error(RuntimeError)
          end
        end
      end
      
      context 'with an error callback' do
        let(:errors) { Array.new }
        
        subject do
          described_class.new(server, reactor) do |client|
            raise 'boom'
          end.on_error do |err|
            errors << err
          end
        end
        
        it 'raises no errors' do
          expect { subject.process }.to_not raise_error
        end
        
        it 'calls an error callback' do
          expect { subject.process }.to change { errors }
        end

        it 'calls an error callback with the exception' do
          subject.process
          expect(errors[0]).to be_kind_of(RuntimeError)
          expect(errors[0].message).to eql('boom')
        end
      end

      context 'with no error callback' do
        exception = Class.new(RuntimeError)
        
        subject do
          described_class.new(server, reactor) do |client|
            raise exception.new('boom')
          end
        end

        it 'raises any exceptions' do
          expect { subject.process }.to raise_error(exception)
        end
      end
    end
  end
end
