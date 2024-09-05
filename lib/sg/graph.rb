require 'matrix'

module SG
  class Graph
    MaxDepth = 6
    
    class EdgeError < ArgumentError
      attr_reader :from, :to
      
      def initialize from, to
        @from = from
        @to = to
        super(to_s)
      end

      def to_s
        "EdgeError: #{from} -> #{to}"
      end
    end
    
    class DuplicateEdgeError < EdgeError
      def to_s
        "Duplicate edge: #{from} -> #{to}"
      end
    end

    class EdgeNotFound < EdgeError
      def to_s
        "Edge not found: #{from} -> #{to}"
      end
    end
    
    class Edge
      attr_accessor :from, :to, :data
      
      def initialize from, to, data
        @from = from
        @to = to
        @data = data
      end

      def to_s
        "%s -> %s" % [ from, to ]
      end
    end

    module EnumerableExt
      def from node
        select { |e| e.from == node }.extend(EnumerableExt)
      end

      def to node
        select { |e| e.to == node }.extend(EnumerableExt)
      end

      def from_to fr, to
        from(fr).to(to).extend(EnumerableExt)
      end
    end
    
    def initialize
      @edges = Hash.new { |h, k| h[k] = Hash.new }
    end

    def add_edge *args
      if args.size == 1
        edge = args[0]
        from = edge.from
        to = edge.to
        data = edge.data
      elsif args.size == 3
        from, to, data = args
      end
      raise DuplicateEdgeError.new(from, to) if find(from, to)
      @edges[from][to] = Edge.new(from, to, data)
    end

    def rm_edge from, to
      raise EdgeNotFound.new(from, to) if !find(from, to)
      @edges[from].delete(to)
      self
    end
    
    def each_edge &block
      return to_enum(__method__) unless block
      
      @edges.each do |src, s_h|
        s_h.each do |dest, edge|
          block.call(edge)
        end
      end
    end

    def each_node &block
      each_edge.collect do |e|
        [ e.from, e.to ]
      end.flatten.uniq.each(&block)
    end
    
    def edge_count
      each_edge.count
    end
    
    def node_count
      each_node.count
    end
    
    def from node
      @edges[node].values
    end

    def to node
      each_edge.select { |e| e.to == node }
    end

    def find fr, to
      @edges[fr][to]
    end

    def eql? other
      self.class === other &&
        edge_count == other.edge_count &&
        each_edge.all? { |e| oe = other.find(e.to, e.from); oe && e.data.eql?(oe.data) }
    end
    
    def route from, to, max_depth = MaxDepth
      paths = route_for(from, to, max_depth)
      paths.each_slice(2)
    end

    def shortest_routes from, to, max_depth = MaxDepth
      route(from, to, max_depth).sort_by { |p| p[0].size }
    end

    def shortest_route from, to, max_depth = MaxDepth
      route(from, to, max_depth).min_by { |p| p[0].size }
    end

    def route_for root, dest, max_depth = MaxDepth, depth = 0, seen = [], path = []
      # for the case when there is a from and an indirect to:
      #  All the conversions for FROM need to be checked for an indirect conversions to DEST
      #puts "#{root} #{dest} #{depth} #{max_depth}"
      return [] if root == dest
      return nil if depth >= max_depth || seen.include?(root)
      new_seen = seen + [ root ]
      edge = find(root, dest)
      if edge
        [ new_seen + [ dest ], (path + [ edge ]) ]
      else
        from(root).collect do |edge|
          route_for(edge.to, dest,
                    max_depth, depth + 1,
                    new_seen,
                    path + [ edge ])
        end.reject(&:nil?).reduce([]) { |a, p| a + p }
      end
    end

    def node_index indexes = nil
      return indexes if Hash === indexes
      (indexes || each_node).each_with_index.
        reduce({}) { |h, (n, i)| h[n] = i; h }
    end
    
    def to_matrix indexes = nil, use_data: true
      indexes = node_index(indexes)
      each_edge.reduce(Matrix.zero(node_count,
                                   node_count)) do |m, e|
        fi = indexes[e.from]
        ti = indexes[e.to]
        m[ti, fi] = use_data ? e.data : 1
        m
      end
    end

    def self.from_matrix m, nodes = nil
      # nodes = Hash[nodes.each_with_index.collect { |n, i| [ n, i ] }] if nodes
      self.new.tap do |g|
        m.row_count.times do |y|
          m.column_count.times do |x|
            f = nodes&.[](y) || y
            t = nodes&.[](x) || x
            g.add_edge(f, t, m[x, y]) if m[x, y] != 0
          end
        end
      end
    end

    def self.generate_ex nodes = 8, edges = 32
      g = self.new
      fails = 0
      edges.times do |n|
        begin
          src, dest = nodes.rand, nodes.rand
          # $stderr.puts("%s\t%s" % [ src, dest ])
          g.add_edge(src, dest, n)
        rescue DuplicateEdgeError
          # $stderr.puts("fail")
          fails += 1
        end
      end
      [ g, fails ]
    end

    def + other
      case other
      when self.class then
        g = self.class.new
        each_edge.chain(other.each_edge).each { |e| g.add_edge(e) }
        g
      when Edge then self.add_edge(other)
      else raise TypeError.new("only graphs and edges can be added to graphs")
      end
    end
  end
end

if $0 == __FILE__
  require 'benchmark'
  Kernel.srand(1234)

  def fmt_path path
    "%i %s" % [ (path[1] || []).collect(&:data).sum, path[0].join(' -> ') ]
  end
  
  Nodes = %w{a b c d e f g h i j k l m n o p q r s t u v w x y z}
  Greek = %W{alpha beta gamma delta epsilon eta}.collect(&:to_sym)
  gn, gn_fails = SG::Graph.generate_ex(Nodes, Nodes.size * 4)
  gg, gg_fails = SG::Graph.generate_ex(Greek, Greek.size ** 2)
  g = gn + gg
  g.add_edge(:eta, 'a', 6)
  g.add_edge('z', :alpha, 6)
  $stderr.puts("Generated %i Latin and %i Greek edges, %i & %i fails" % [ gn.edge_count, gg.edge_count, gn_fails, gg_fails ])

  if ARGV[0] == 'dot'
    all_nodes = g.each_node.to_a
    puts("digraph {")
    g.each_node { |n| puts("%s [label=%s];" % [ n.to_s.dump, n.to_s.dump ]) }
    g.each_edge { |e| puts("%s -> %s [penwidth=1];" % [ e.from.to_s.dump, e.to.to_s.dump ]) }
    %w{red green blue}.each do |color|
      src, dest = all_nodes.rand, all_nodes.rand
      $stderr.puts("Routing #{src} -> #{dest}")
      path = g.shortest_routes(src, dest)
      unless path.empty?
        puts("%s [color=%s,penwidth=6];" % [ path[0][0].collect { |p| p.to_s.dump }.join(" -> "), color ])
      end
      path = g.shortest_routes(dest, src)
      unless path.empty?
        puts("%s [color=%s,penwidth=4];" % [ path[0][0].collect { |p| p.to_s.dump }.join(" -> "), color ])
      end
    end
    puts("}")
  else
    Benchmark.bm do |bm|
      puts(g.from(:beta))
      puts
      puts(g.find(:delta, :alpha))
      [ [ :alpha, :gamma ],
        [ :alpha, :delta ],
        [ :delta, :gamma ],
        [ :eta, :alpha ],
        [ :alpha, :eta ]
      ].each do |(from, to)|
        puts
        puts("#{from} to #{to}:")
        bm.report do
          puts(g.shortest_routes(from, to).
               first(5).
               collect { |p| fmt_path(p) })
        end
        bm.report do
          puts(fmt_path(g.shortest_route(from, to) || [[]]))
        end
      end
    end

    5.times do
      from = Nodes.rand
      to = Nodes.rand
      puts
      puts("#{from} to #{to}:")
      routes = g.shortest_routes(from, to)
      if routes.empty?
        puts("No route")
      else
        puts(routes[0,3].collect { |p| fmt_path(p) })
        puts(fmt_path(routes[-1]))
      end
    end
    
    puts
    puts("A to B:")
    routes = g.shortest_routes('a', 'b')
    puts(routes[0,3].collect { |p| fmt_path(p) })
    puts(fmt_path(routes[-1]))
  end
end
