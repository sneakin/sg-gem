require 'sg/ext'
using SG::Ext

require_relative 'defer'

describe SG::Defer do
  def wait_for(...); SG::Defer.wait_for(...); end
  
  describe '.wait_for' do
    let(:a) { SG::Defer::Value.new { :a } }
    let(:b) { SG::Defer::Value.new { :b } }

    describe 'values' do
      it 'returns the value' do
        expect(wait_for(123)).to eql(123)
      end
    end

    describe 'deferred values' do
      let(:value) { SG::Defer::Value.new { 234 } }

      it 'waits and returns' do
        allow(value).to receive(:wait).and_return(100)
        expect(wait_for(value)).to eql(100)
      end
    end
    
    describe 'Defer::Able' do
      let(:able) do
        Class.new do
          include SG::Defer::Able
          def wait; 200; end
        end
      end
      let(:value) { able.new }

      it { expect(wait_for(value)).to eql(200) }
    end

    describe 'no args' do
      it { expect { wait_for() }.to raise_error(ArgumentError) }
    end

    describe 'array' do
      it do
        expect(wait_for([ 1, a, 3, b, 5 ])).
          to eql([1, :a, 3, :b, 5 ])
      end
      
      it do
        expect(wait_for([ 1, a, [3, [b, 5 ]]])).
          to eql([1, :a, [3, [:b, 5 ]]])
      end
    end

    describe 'Enumerable' do
      it do
        expect(wait_for([ 1, a, 3, b, 5 ].each)).
          to eql([1, :a, 3, :b, 5 ])
      end
    end

    describe 'hash' do
      it do
        expect(wait_for({ x: a, y: b, z: :c })).
          to eql({x: :a, y: :b, z: :c })
      end

      it do
        expect(wait_for({ x: a, y: { w: a, v: [ b ] }, z: :c })).
          to eql({x: :a, y: { w: :a, v: [ :b ] }, z: :c })
      end
    end
  end
end
