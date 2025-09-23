require 'sg/ext'

using SG::Ext

describe Proc do
  let(:divider) do
    described_class.new do |x, y|
      raise 'dead' if x == 0xDEAD
      x / y
    end
  end
  
  subject { divider }

  describe '#but' do
    describe 'without a block' do
      it 'returns the proc' do
        expect(subject.but).to eq(subject)
      end

      it 'raises errors' do
        expect { subject.but.call(3, 0) }.to raise_error(ZeroDivisionError)
      end
    end

    describe 'with a block' do
      let(:on_err) do
        Proc.new { |ex|
          @caught = ex
        }
      end

      subject do
        divider.but(ZeroDivisionError, &on_err)
      end
      
      it 'sets #on_error to the block' do
        expect(subject.on_error).to be(on_err)
      end

      it 'sets #fn to the original proc' do
        expect(subject.fn).to be(divider)
      end

      it 'calls the block on exceptions' do
        expect { subject.call(3, 0) }.to change { @caught }
      end
      
      it 'passes along returns' do
        expect(subject.call(6, 2)).to eq(3)
      end
    end

    describe 'as a block argument' do
      subject do
        divider.but(ZeroDivisionError) { @caught = _1 }
      end

      def fn x, y
        yield(x, y)
      end
      
      it 'calls the block on exceptions' do
        expect { fn(3, 0, &subject) }.to change { @caught }
      end
      
      it 'raises unhandled exceptions' do
        expect { fn(0xDEAD, 1, &subject) }.to raise_error('dead')
      end
      
      it 'passes along returns' do
        expect(fn(6, 2, &subject)).to eq(3)
      end
    end
    
  end

  describe '#catch' do
    describe 'without a block' do
      it 'returns the proc' do
        expect(subject.catch).to eq(subject)
      end

      it 'raises errors' do
        expect { subject.catch.call(3, 0) }.to raise_error(ZeroDivisionError)
      end
    end

    describe 'with a block' do
      let(:on_err) do
        Proc.new { |ex|
          @caught = ex
        }
      end

      subject do
        divider.catch(ZeroDivisionError, &on_err)
      end
      
      it 'calls the block on exceptions' do
        expect { subject.call(3, 0) }.to change { @caught }
      end
      
      it 'raises unhandled exceptions' do
        expect { subject.call(0xDEAD, 1) }.to raise_error('dead')
      end
      
      it 'passes along returns' do
        expect(subject.call(6, 2)).to eq(3)
      end
    end

    describe 'as a block argument' do
      subject do
        divider.catch(ZeroDivisionError) { @caught = _1 }
      end

      def fn x, y
        yield(x, y)
      end
      
      it 'calls the block on exceptions' do
        expect { fn(3, 0, &subject) }.to change { @caught }
      end
      
      it 'raises unhandled exceptions' do
        expect { fn(0xDEAD, 1, &subject) }.to raise_error('dead')
      end
      
      it 'passes along returns' do
        expect(fn(6, 2, &subject)).to eq(3)
      end
    end

    describe 'with another block' do
      subject do
        divider.catch(ZeroDivisionError) { @caught = _1 }
      end
      
      it 'catches the error' do
        expect { subject.call(100, 0) }.to_not raise_error
      end

      it 'catches the error' do
        expect { subject.call(100, 0) }.
          to change { @caught }.to be_kind_of(ZeroDivisionError)
      end
    end

    describe 'with no exceptions listed and no block' do
      it 'returns itself' do
        expect(subject.catch).to be(subject)
      end
    end
    
    describe 'with exceptions listed and no block' do
      it 'returns itself' do
        expect { subject.catch(ZeroDivisionError) }.to_not raise_error
      end
    end
    
    describe 'with no exceptions listed and a block' do
      subject do
        Proc.new do
          raise 'boom'
        end.catch { @caught = _1 }
      end
      
      it 'catches the error' do
        expect { subject.call }.to_not raise_error
      end

      it 'catches the error' do
        expect { subject.call }.to change { @caught }
      end
    end
  end
end
