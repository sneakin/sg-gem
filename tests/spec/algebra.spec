require 'sg/algebra'
require 'sg/csv'

describe SG::Algebra do
  it 'provides symbolic math' do
    # Plug and chug
    f = SG::Algebra() { x ** 2 + y }
    expect(f.call(x: 4)).to eq(4 ** 2 + SG::Algebra::Symbol.new(:y))
    expect(f.call).to eql(f)

    # Do more with expressions:
    g = f / SG::Algebra::Symbol.new(:z)
    expect(g.call(x: 4, y: 3, z: 2)).to eq((4 ** 2 + 3) / 2)
    expect(g.call(x: 4, y: 3)).to eq((4 ** 2 + 3) / SG::Algebra::Symbol.new(:z))
    expect(g.call(x: 4, z: 2)).to eq(SG::Algebra() { (4 ** 2 + y) / 2})
    # Plug in expressions
    expect(g.call(z: SG::Algebra() { x ** 2 })).
      to eql(SG::Algebra() { ((x ** 2) + y) / (x ** 2) })
    # And simplify
    expect(SG::Algebra.simplify(g.call(z: SG::Algebra() { x ** 2 }))).
      to eql(SG::Algebra() { 1 + y / (x ** 2) })
  end

  describe '.simplify' do
    test_cases = Pathname.new(__FILE__).parent.
      join('algebra-rules.csv').
      open { SG::CSV.read(_1) }
    
    test_cases.each do |(input, output)|
      input = SG::Algebra(input)
      output = if String === output && output =~ /\A[A-Z][A-Za-z_]+\Z/
                 const_get(output)
               else
                 SG::Algebra(output)
               end
      
      if Class === output
        it "raises #{output} for #{input}" do
          expect { SG::Algebra.simplify(input) }.
            to raise_error(output)
        end
      else
        it "simplifies #{input} to #{output}" do
          expect(SG::Algebra.simplify(input)).
            to eql(output)
        end
      end
    end
  end
end
