# -*- coding: utf-8 -*-
require 'sg/units'

using SG::Ext

describe SG::Units do
  let(:usd) { SG::Units::Unit.derive('USD', 'USD') } #'$%.2f'.to_proc)
  let(:cents) { SG::Units.scaled_unit('cents', usd, 0.01, abbrev: 'US¢') } #'%i¢'.to_proc)
  let(:btc) { SG::Units::Unit.derive('BTC', 'BTC') } #'$%.2f'.to_proc)
  let(:eur) { SG::Units::Unit.derive('EUR', 'EUR') } #'$%.2f'.to_proc)

  before do
    SG::Converter.register_scaler(btc, usd, 100000)    
  end

  describe 'unit operations' do
    it { expect(usd.name).to eq('USD') }
    it { expect(usd.abbrev).to eq('USD') }
    it { expect(usd.dimension.name).to eq('USD') }
    it { expect(btc.name).to eq('BTC') }
    it { expect(btc.abbrev).to eq('BTC') }
    it { expect(btc.dimension.name).to eq('BTC') }

    it { expect(usd * btc).to be_kind_of(Class) }
    it { expect { usd / 0 }.to raise_error(ZeroDivisionError) }
    it { expect(usd / btc).to be_kind_of(Class) }
    it { expect(usd / usd).to eql(SG::Units::Unitless) }
    it { expect((usd / usd).new(3)).to eql(SG::Units::Unitless.new(3)) }
    it { expect((usd / cents).new(10)).to be_kind_of(SG::Units::Unit::Per) }
    it { expect(usd / btc * btc).to eql(usd) }
    it { expect(usd * btc / btc).to eql(usd) }
    it { expect(usd / (btc * eur)).to eql(usd / btc / eur) }
    it { expect(usd * (btc / eur)).to eql(usd * btc / eur) }
    it { expect(usd * (btc * eur)).to eql(usd * btc * eur) }
    it { expect(usd / (btc / eur)).to eql(usd / btc * eur) }

    it { expect(usd.invert).to eql(SG::Units::Unit::Per.derive(SG::Units::Unitless, usd)) }
    it { expect(usd.invert.invert).to eql(usd) }
    it { expect(usd * usd.invert).to eql(SG::Units::Unitless) }
    it { expect(usd.invert * usd).to eql(SG::Units::Unitless) }
  end

  describe 'subclassing' do
    context 'by of a Product' do
      let(:child) do
        Class.new(usd * btc)
      end

      it { expect(child.name).to eql('USD*BTC') }
      it { expect(child.abbrev).to eql('USD*BTC') }
      it { expect(child.dimension).to eql(usd.dimension * btc.dimension) }
    end

    context 'by of a Per' do
      let(:child) do
        Class.new(usd / btc)
      end

      it { expect(child.name).to eql('USD / BTC') }
      it { expect(child.abbrev).to eql('USD/BTC') }
      it { expect(child.dimension).to eql(usd.dimension / btc.dimension) }
    end
  end
  
  describe '#to_s' do
    it { expect(usd.new(100).to_s).to eq('100 USD') }
    it { expect(cents.new(100).to_s).to eq('100 US¢') }
    it { expect(btc.new(100).to_s).to eq('100 BTC') }
  end

  describe 'intra-dimensional auto conversion' do
    it { expect(usd.new(100)).to eq(cents.new(10000)) }
    it { expect(cents.new(50)).to eq(usd.new(0.50)) }
    it { expect(usd.new(100).eq?(btc.new(0.0003))).to eq(false) }
  end

  describe '#+' do
    it { expect(+usd.new(10)).to eq(usd.new(10)) }
    it { expect(usd.new(100) + usd.new(50)).to eq(usd.new(150)) }
    it { expect(usd.new(100) + cents.new(50)).to eq(usd.new(100.50)) }
    it { expect { usd.new(100) + btc.new(0.0003) }.
      to raise_error(SG::Units::DimensionMismatch) }
    it { expect { 100 + btc.new(0.0003) }.
      to raise_error(SG::Units::DimensionMismatch) }
    it { expect { usd.new(100) + 0.03 }.
      to raise_error(SG::Units::DimensionMismatch) }
  end

  describe '#-' do
    it { expect(-usd.new(10)).to eq(usd.new(-10)) }
    it { expect(usd.new(100) - usd.new(50)).to eq(usd.new(50)) }
    it { expect(usd.new(100) - cents.new(50)).to eq(usd.new(99.50)) }
    it { expect { usd.new(100) - btc.new(0.0003) }.
      to raise_error(SG::Units::DimensionMismatch) }
    it { expect { 100 - btc.new(0.0003) }.
      to raise_error(SG::Units::DimensionMismatch) }
    it { expect { usd.new(100) - 0.03 }.
      to raise_error(SG::Units::DimensionMismatch) }
  end

  describe '#*' do
    it { expect((usd * usd).new(10)).to be_kind_of(SG::Units::Unit::Product) }
    it { expect((usd * btc).new(10)).to be_kind_of(SG::Units::Unit::Product) }
    it { expect(usd.new(100) * usd.new(50)).to eq((usd * usd).new(5000)) }
    it { expect(usd.new(100) * cents.new(50)).to eq((usd * usd).new(50)) }
    it { expect(usd.new(100) * btc.new(0.0001)).to eq((usd * btc).new(0.01)) }
    it { expect(100 * usd.new(50)).to eq(usd.new(5000)) }
    it { expect(usd.new(100) * 50).to eq(usd.new(5000)) }
  end

  describe '#/' do
    it { expect((usd / usd).new(10)).to eq(10) }
    it { expect((usd / btc).new(10)).to be_kind_of(SG::Units::Unit::Per) }
    it { expect((usd / btc * btc).new(10)).to be_kind_of(usd) }
    it { expect((btc * usd / btc).new(10)).to be_kind_of(usd) }
    it { expect((btc * usd * btc / usd / btc / btc).new(10)).to be_kind_of(SG::Units::Unitless) }
    it { expect((btc * usd * btc / btc / usd / btc).new(10)).to be_kind_of(SG::Units::Unitless) }
    it { expect((btc * usd * btc / btc / btc / usd).new(10)).to be_kind_of(SG::Units::Unitless) }
    it { expect { usd.new(10) / 0 }.to raise_error(ZeroDivisionError) }
    it { expect { usd.new(10) / usd.new(0) }.to raise_error(ZeroDivisionError) }
    it { expect(usd.new(100) / usd.new(50)).to eq(2) }
    it { expect(usd.new(100) / cents.new(50)).to eq(200.0) }
    it { expect(usd.new(100) / btc.new(0.0001)).to eq((usd / btc).new(1000000.0)) }
    it { expect(usd.new(100) / btc.new(0.0001) * btc.new(10)).to eq(usd.new(10000000.0)) }
    it { expect(btc.new(10) * usd.new(100) / btc.new(0.0001)).to eq(usd.new(10000000.0)) }
    it { expect(100 / usd.new(50.0)).to eq(usd.invert.new(2)) }
    it { expect(usd.new(100) / 50).to eq(usd.new(2)) }

    it {
      expect(SG::Units::Inch.new(100) / SG::Units::Second.new(30.0) * SG::Units::Gram.new(5) / SG::Units::Inch.new(3.0)).
      to be_kind_of(SG::Units::Inch / SG::Units::Second * SG::Units::Gram / SG::Units::Inch)
    }
    it {
      expect(SG::Units::Inch.new(100) / SG::Units::Second.new(30) * SG::Units::Gram.new(5) / SG::Units::Inch.new(3)).
      to eql((SG::Units::Inch / SG::Units::Second * SG::Units::Gram / SG::Units::Inch).new(5))
    }

    it { expect(usd*btc / (usd*btc)).to eql(SG::Units::Unitless) }
    it { expect(usd.new(100)*btc.new(0.5) / (usd.new(100)*btc.new(0.5))).to eql(SG::Units::Unitless.new(1.0)) }
    it { expect(usd.new(100)*btc.new(0.5) / (usd.new(100)*btc.new(0.5))).to eql(SG::Units::Unitless.new(1.0)) }

    it { expect(usd*btc*eur / (usd*btc)).to eql(eur) }
    it { expect(usd.new(100)*btc.new(0.5)*eur.new(2) / (usd.new(100)*btc.new(0.5))).to eql(eur.new(2.0)) }
  end

  describe '#invert' do
    it { expect(usd.new(100.0).invert).to eql(usd.invert.new(0.01)) }
    it { expect(usd.new(100.0).invert.invert).to eql(usd.new(100.0)) }
  end

  describe '.cancel' do
    it { expect((usd * btc * eur).cancel(eur)).to eql(usd*btc) }
    it { expect((usd * btc * eur).cancel(eur*usd)).to eql(btc) }
  end
end

describe SG::Units::Unitless do
  describe 'conversions' do
    it { expect(described_class.new(5).to_s).to eq('5') }
    it { expect(described_class.new(5).to_i).to eq(5) }
    it { expect(described_class.new(5).to_f).to eq(5.0) }
    it { expect(described_class.new(5).to_r).to eq(5.to_r) }
  end

  describe '#==' do
    it { expect(described_class.new(10) == 10).to be(true) }
    it { expect(described_class.new(5) == 10).to be(false) }
    it { expect(10 == described_class.new(10)).to be(true) }
    it { expect(5 == described_class.new(10)).to be(false) }
    it { expect(described_class.new(5) == described_class.new(5)).to be(true) }
    it { expect(described_class.new(10) == described_class.new(5)).to be(false) }
    it { expect(described_class.new(5) == described_class.new(10)).to be(false) }
    it { expect(described_class.new(5) == SG::Units::Inch.new(5)).to be(false) }
    it { expect(SG::Units::Inch.new(5) == described_class.new(5)).to be(false) }
  end

  describe '#+' do
    it { expect(described_class.new(5) + 5).to eq(10) }
    it { expect(5 + described_class.new(5)).to eq(10) }
    it { expect { described_class.new(5) + SG::Units::Inch.new(5) }.to raise_error(SG::Units::DimensionMismatch) }
    it { expect { SG::Units::Inch.new(5) + described_class.new(5) }.to raise_error(SG::Units::DimensionMismatch) }
  end

  describe '#-' do
    it { expect(described_class.new(10) - 5).to eq(5) }
    it { expect(5 - described_class.new(2)).to eq(3) }
    it { expect { described_class.new(5) - SG::Units::Inch.new(5) }.to raise_error(SG::Units::DimensionMismatch) }
    it { expect { SG::Units::Inch.new(5) - described_class.new(5) }.to raise_error(SG::Units::DimensionMismatch) }
  end

  describe '#*' do
    it { expect(described_class.new(10) * 5).to eq(50) }
    it { expect(5 * described_class.new(2)).to eq(10) }
    it { expect(described_class.new(10) * SG::Units::Inch.new(5)).to eq(SG::Units::Inch.new(50)) }
    it { expect(SG::Units::Inch.new(5) * described_class.new(10)).to eq(SG::Units::Inch.new(50)) }
  end

  describe '#/' do
    it { expect(described_class.new(10) / 5).to eq(2) }
    it { expect(10 / described_class.new(2)).to eq(5) }
    it { expect(described_class.new(10) / SG::Units::Inch.new(5)).to eq(SG::Units::Inch.invert.new(2)) }
    it { expect(SG::Units::Inch.new(5) / described_class.new(10.0)).to eq(SG::Units::Inch.new(0.5)) }
  end
end

describe SG::Units::Dimension do
  let(:dim1) { described_class.new('dim1') }
  let(:dim2) { described_class.new('dim2') }
  let(:dim3) { described_class.new('dim3') }

  it { expect(dim1 * dim2 / dim2).to eq(dim1) }
  it { expect(dim1 * dim2 / dim1).to eq(dim2) }
  it { expect(dim1 * dim2 * dim3 / dim1 / dim2).to eq(dim3) }
  it { expect(dim1 / dim1).to eq(SG::Units::NullDimension) }
  it { expect(1 / dim1 * dim1).to eq(SG::Units::NullDimension) }
  it { expect { dim1 / 0 }.to raise_error(ZeroDivisionError) }

  it { expect(dim1.invert * dim1).to eq(SG::Units::NullDimension) }

  it { expect(dim1*dim2 / (dim1*dim2)).to eql(SG::Units::NullDimension) }
  it { expect(dim1*dim2*dim3 / (dim1*dim2)).to eql(dim3) }
  it { expect(dim1*(dim2/dim3)).to eql(dim1*dim2/dim3) }

  describe '.cancel' do
    it { expect((dim1 * dim2 * dim3).cancel(dim3)).to eql(dim1*dim2) }
    it { expect((dim1 * dim2 * dim3).cancel(dim3*dim1)).to eql(dim2) }
  end
  
end

describe SG::Units do
  it { expect(SG::Units::Length).to be_kind_of(SG::Units::Dimension) }
  %w{ Inch Foot Meter Yard Mile }.each do |unit|
    it { expect(SG::Units.const_get(unit).dimension).to eql(SG::Units::Length) }
  end

  it { expect(SG::Units::Time).to be_kind_of(SG::Units::Dimension) }
  %w{ Second Minute Hour Day Week Year }.each do |unit|
    it { expect(SG::Units.const_get(unit).dimension).to eql(SG::Units::Time) }
  end

  it { expect(SG::Units::Velocity).to eql(SG::Units::Length / SG::Units::Time) }
  it { expect(SG::Units::Acceleration).to eql(SG::Units::Velocity / SG::Units::Time) }
  it { expect(SG::Units::Force).to eql(SG::Units::Mass * SG::Units::Acceleration) }
  it { expect(SG::Units::Newton.dimension).to eql(SG::Units::Force) }
  it { expect(SG::Units::Pound.dimension).to eql(SG::Units::Force) }
  it { expect(SG::Units::Energy).to eql(SG::Units::Force * SG::Units::Length) }
  it { expect(SG::Units::Joule.dimension).to eql(SG::Units::Energy) }
end
