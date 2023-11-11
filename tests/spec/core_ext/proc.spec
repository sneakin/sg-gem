require 'sg/ext'

using SG::Ext

describe SG::Ext::RescuedProc do
  let(:fn) { Proc.new { |x, y| x / y } }
  let(:cb) { lambda { |ex| @ex = ex } }
  subject do
    described_class.new(fn, ZeroDivisionError, &cb)
  end

  it { expect(subject).to be_kind_of(Proc) }
  it { expect(subject.fn).to be(fn) }
  it { expect(subject.on_error).to be(cb) }
  it { expect(subject.exceptions).to eq([ ZeroDivisionError ]) }
  it { expect(subject.call(6, 3)).to eq(2) }
  it { expect { subject.call(6, 0) }.to change { @ex }.to(ZeroDivisionError) }
end

describe Proc do
  subject { Proc.new { |x, y| x / y } }

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
        expect(subject.call(6, 2)).to eq(3)
      end
    end
  end
end
