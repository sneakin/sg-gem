require 'sg/core_ext/proc'

describe Proc do
  subject { Proc.new { |x, y| x / y } }

  describe '#fn' do
    it { expect(subject.fn).to be(subject) }

    describe 'after setting' do
      it { expect { subject.fn = 3 }.to change(subject, :fn).to(3) }
    end
  end
  
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

      let(:fn) do
        Proc.new { |x, y| x / y }
      end
      
      subject do
        fn.but(ZeroDivisionError, &on_err)
      end
      
      it 'sets #on_error to the block' do
        expect(subject.on_error).to be(on_err)
      end

      it 'sets #fn to the original proc' do
        expect(subject.fn).to be(fn)
      end

      it 'calls the block on exceptions' do
        expect { subject.call(3, 0) }.to change { @caught }
      end
      
      it 'passes along returns' do
        expect(subject.call(6, 2)).to be(3)
      end
    end
  end
end
