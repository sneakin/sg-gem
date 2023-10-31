require 'sg/algebra'

describe SG::Algebra do
  it 'provides symbolic math' do
    f = SG::Algebra::Symbol.new(:x) ** 2 + SG::Algebra::Symbol.new(:y)
    expect(f.call(x: 4)).to eq(4 ** 2 + SG::Algebra::Symbol.new(:y))

    g = f / SG::Algebra::Symbol.new(:z)
    expect(g.call(x: 4, y: 3, z: 2)).to eq((4 ** 2 + 3) / 2)
    expect(g.call(x: 4, y: 3)).to eq((4 ** 2 + 3) / SG::Algebra::Symbol.new(:z))
    expect(g.call(x: 4, z: 2)).to eq((4 ** 2 + SG::Algebra::Symbol.new(:y)) / 2)
  end
end
