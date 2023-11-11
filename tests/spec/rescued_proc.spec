require 'sg/ext'

using SG::Ext

describe SG::RescuedProc do
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
