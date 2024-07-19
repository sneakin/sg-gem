require 'sg/converter'

using SG::Ext

describe SG::Converter do
  describe '.convert' do
    [ # Numbers
     [ 100, String, '100' ],
     [ '100', Integer, 100 ],
     [ 12.3, String, '12.3' ],
     [ '12.3', Float, 12.3 ],
     # Complex
     [ 123, Complex, Complex.rect(123, 0) ],
     [ Complex.rect(123, 45), String, '123+45i' ],
     [ '-12.3+45i', Complex, Complex.rect(-12.3, 45.0) ],
     [ '12.3-45i', Complex, Complex.rect(12.3, -45.0) ],
     [ Complex.rect(123, 45), Integer, 123 ],
     [ Complex.rect(123.12, 45), Float, 123.12 ],
     # arrays
     [ [ 12, 34 ], String, '[12, 34]' ],
     #[ '[12, 34]', Array, [ 12, 34 ] ],
     # hashes
     [ { a: 12, 'b' => 34 }, String, '{:a=>12, "b"=>34}' ],
     #[ '{ a: 12, "b" => 34 }', Hash, { a: 12, "b" => 34 } ],
     # JSON
     [ [ 12, 34 ], JSON, '[12,34]' ],
     [ '[ 12, 34 ]', JSON, [ 12, 34 ] ],
     [ { a: 12, b: 34 }, JSON, '{"a":12,"b":34}' ],
     [ '{ "a": 12, "b": 34 }', JSON, { 'a' => 12, 'b' => 34 } ]
    ].each do |(input, type, output)|
      it "(#{input.inspect}, #{type.inspect}) => #{output.inspect}" do
        expect(described_class.convert(input, type)).to eql(output)
      end
    end

    it "errors for bad conversions"  do
      expect { puts(described_class.convert(123, Array).inspect) }.
        to raise_error(SG::Converter::NoConverterError)
    end
  end

  describe '.for' do
    it "errors for bad conversions" do
      expect { described_class.for(Array, Hash) }.
        to raise_error(SG::Converter::NoConverterError)
    end
  end

  it 'refined String' do
    expect('123'.to(Integer)).to eql(123)
  end

  it 'refined Integer' do
    expect(123.to(Float)).to eql(123.0)
  end

  it 'refined Float' do
    expect(123.34.to(String)).to eql('123.34')
  end
end
