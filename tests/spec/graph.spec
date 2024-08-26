require 'sg/graph'
#require 'sg/ext'
#using SG:Ext

describe SG::Graph do
  context 'some nodes and edges' do
    before do
      subject.add_edge('Alice', 'Bob', :ab)
      subject.add_edge('Alice', 'Cathy', :ab)
      subject.add_edge('Bob', 'Cathy', :ab)
      subject.add_edge('Bob', 'Alice', :ab)
      subject.add_edge('Cathy', 'Bob', :ab)
      subject.add_edge('Cathy', 'Dave', :ab)
      subject.add_edge('Cathy', 'Edward', :ab)
      subject.add_edge('Dave', 'Bob', :ab)
      subject.add_edge('Dave', 'Alice', :ab)
      subject.add_edge('Edward', 'Cathy', :ab)
      subject.add_edge('Edward', 'Fred', :ab)
      subject.add_edge('Fred', 'George', :ab)
      subject.add_edge('George', 'Harry', :ab)
    end

    it { expect(subject.edge_count).to eql(13) }
    it { expect(subject.node_count).to eql(8) }

    it { expect { subject.add_edge('Cathy', 'Edward', :ab) }.
      to raise_error(SG::Graph::DuplicateEdgeError) }

    it { expect(subject.each_node.sort.to_a).
      to eql(%w{Alice Bob Cathy Dave Edward Fred George Harry}) }
    it { expect(subject.each_edge.count).to eql(13) }
    
    describe '#rm_edge' do
      it { expect { subject.rm_edge('Alice', 'Bob') }.
        to change { subject.find('Alice', 'Bob') }.
        to eql(nil) }
      it { expect { subject.rm_edge('Alice', 'Jane') }.
        to raise_error(SG::Graph::EdgeNotFound) }
     end

    def edge_set nodes
      nodes[0..-2].each.zip(nodes.each.drop(1)).
        collect { |f, t| subject.find(f, t) }
    end

    def path nodes
      [ nodes, edge_set(nodes) ]
    end
    
    describe '#route' do
      it { expect(subject.route('Alice', 'Bob').to_a).
        to eql([ path(%w{Alice Bob})]) }
      it { expect(subject.route('Alice', 'Dave').to_a).
        to eql([ path([ 'Alice', 'Bob', 'Cathy', 'Dave' ]),
                 path([ 'Alice', 'Cathy', 'Dave' ]) ]) }
      it { expect(subject.route('Alice', 'Edward').to_a).
        to eql([ path([ 'Alice', 'Bob', 'Cathy', 'Edward' ]),
                 path([ 'Alice', 'Cathy', 'Edward' ])]) }
      it { expect(subject.route('Edward', 'Alice').to_a).
        to eql([ path([ 'Edward', 'Cathy', 'Bob', 'Alice' ]),
                 path([ 'Edward', 'Cathy', 'Dave', 'Alice' ]) ]) }
      it { expect(subject.route('Alice', 'Harry').to_a).
        to eql([ path([ 'Alice', 'Bob', 'Cathy', 'Edward', 'Fred', 'George', 'Harry' ]),
                 path([ 'Alice', 'Cathy', 'Edward', 'Fred', 'George', 'Harry' ])]) }

      it { expect(subject.route('Fred', 'Alice').to_a).to eql([]) }

      it { expect(subject.route('Alice', 'Edward', 2).to_a).
        to eql([ path([ 'Alice', 'Cathy', 'Edward' ])]) }
      it { expect(subject.route('Alice', 'Edward', 1).to_a).
        to eql([]) }
    end

    describe '#shortest_routes' do
      it { expect(subject.shortest_routes('Alice', 'Bob').to_a).
        to eql([ path([ 'Alice', 'Bob' ])]) }
      it { expect(subject.shortest_routes('Alice', 'Dave').to_a).
        to eql([ path([ 'Alice', 'Cathy', 'Dave' ]),
                 path([ 'Alice', 'Bob', 'Cathy', 'Dave' ]) ]) }
      it { expect(subject.shortest_routes('Alice', 'Edward').to_a).
        to eql([ path([ 'Alice', 'Cathy', 'Edward' ]),
                 path([ 'Alice', 'Bob', 'Cathy', 'Edward' ]) ]) }
      it { expect(subject.shortest_routes('Edward', 'Alice').to_a).
        to eql([ path([ 'Edward', 'Cathy', 'Bob', 'Alice' ]),
                 path([ 'Edward', 'Cathy', 'Dave', 'Alice' ]) ]) }
      it { expect(subject.shortest_routes('Alice', 'Harry').to_a).
        to eql([ path([ 'Alice', 'Cathy', 'Edward', 'Fred', 'George', 'Harry' ]),
                 path([ 'Alice', 'Bob', 'Cathy', 'Edward', 'Fred', 'George', 'Harry' ])]) }
      
      it { expect(subject.shortest_routes('Fred', 'Alice').to_a).to eql([]) }

      it { expect(subject.shortest_routes('Alice', 'Edward', 2).to_a).
        to eql([ path([ 'Alice', 'Cathy', 'Edward' ])]) }
      it { expect(subject.shortest_routes('Alice', 'Edward', 1).to_a).
        to eql([]) }
    end

    describe '#shortest_route' do
      it { expect(subject.shortest_route('Alice', 'Bob')).
        to eql(path([ 'Alice', 'Bob' ])) }
      it { expect(subject.shortest_route('Alice', 'Dave')).
        to eql(path([ 'Alice', 'Cathy', 'Dave' ])) }
      it { expect(subject.shortest_route('Alice', 'Edward')).
        to eql(path([ 'Alice', 'Cathy', 'Edward' ])) }
      it { expect(subject.shortest_route('Edward', 'Alice')).
        to eql(path([ 'Edward', 'Cathy', 'Bob', 'Alice' ])) }
      it { expect(subject.shortest_route('Alice', 'Harry').to_a).
        to eql(path([ 'Alice', 'Cathy', 'Edward', 'Fred', 'George', 'Harry' ])) }

      it { expect(subject.shortest_route('Fred', 'Alice')).
        to eql(nil) }

      it { expect(subject.shortest_route('Alice', 'Edward', 2)).
        to eql(path([ 'Alice', 'Cathy', 'Edward' ])) }
      it { expect(subject.shortest_route('Alice', 'Edward', 1)).
        to eql(nil) }
    end

  end

  describe 'matrix conversion' do
    before do
      subject.add_edge(:a, :b, 1)
      subject.add_edge(:b, :c, 2)
      subject.add_edge(:c, :d, 3)
    end
    
    it 'returns a Matrix using the node list to index the matrix' do
      expect(subject.to_matrix([ :a, :b, :c, :d ])).
        to eql(Matrix[[0, 0, 0, 0],
                      [1, 0, 0, 0 ],
                      [0, 2, 0, 0],
                      [0, 0, 3, 0]])
    end

    it 'with ~use_data~ set to false the cells are set to 1' do
      expect(subject.to_matrix([ :a, :b, :c, :d ], use_data: false)).
        to eql(Matrix[[0, 0, 0, 0],
                      [1, 0, 0, 0 ],
                      [0, 1, 0, 0],
                      [0, 0, 1, 0]])
    end

    it 'populates a graph using a matrix and a node list' do
      expect(described_class.
                from_matrix(Matrix[[0, 1, 0, 0],
                                   [0, 0, 2, 0 ],
                                   [0, 0, 0, 3],
                                   [0, 0, 0, 0]],
                            [ :a, :b, :c, :d ])).
        to eql(subject)
    end

    it 'can round trip the matrices' do
      mat = Matrix[[0, 1, 0, 0],
                   [0, 0, 2, 0 ],
                   [0, 0, 0, 3],
                   [0, 0, 0, 0]]
      expect(described_class.
             from_matrix(mat,
                         [ :a, :b, :c, :d ]).
             to_matrix([ :a, :b, :c, :d ])).
      to eql(mat)
    end
  end
end
