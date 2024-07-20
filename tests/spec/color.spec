require 'sg/color'

using SG::Ext

describe SG::Color do
  describe ' conversions' do
    describe 'from VT100' do
      describe 'to RGB' do
        it do
          expect(SG::Color::VT100.new('blue').to(SG::Color::RGB)).
            to eql(SG::Color::RGB.new(0, 0, 128))
        end
      end
      describe 'to HSL' do
        it do
          expect(SG::Color::VT100.new('blue').to(SG::Color::HSL).to_s).
            to eql(SG::Color::HSL.new(240.0, 1.0, 0.250980).to_s)
        end
      end
    end
  end
end
