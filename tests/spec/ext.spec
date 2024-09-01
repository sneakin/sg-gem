require 'sg/ext'

using SG::Ext

shared_examples 'inheritable attributes' do
  it 'changes the value' do
    expect { klass.beta = 123 }.
      to change { klass.beta }.from(nil).to(123)
  end
  
  describe 'in a subclass' do
    let(:subklass) do
      Class.new(klass) do
      end
    end

    it 'changes the value' do
      expect { subklass.alpha = 123 }.
        to change { subklass.alpha }.from(nil).to(123)
    end
    
    it 'does not change the superclass value' do
      expect { subklass.alpha = 123 }.
        to_not change { klass.alpha }
    end
  end
end

describe FalseClass do
  subject { false }

  describe '#true?' do
    it { expect(subject.true?).to be(false) }
  end

  describe '#false?' do
    it { expect(subject.false?).to be(true) }
  end

  describe '#blank?' do
    it { expect(subject.blank?).to be(true) }
  end
end

describe NilClass do
  subject { nil }

  describe '#true?' do
    it { expect(subject.true?).to be(false) }
  end

  describe '#false?' do
    it { expect(subject.false?).to be(true) }
  end

  describe '#blank?' do
    it { expect(subject.blank?).to be(true) }
  end
end

describe TrueClass do
  subject { true }

  describe '#true?' do
    it { expect(subject.true?).to be(true) }
  end

  describe '#false?' do
    it { expect(subject.false?).to be(false) }
  end

  describe '#blank?' do
    it { expect(subject.blank?).to be(false) }
  end
end

shared_examples 'delegated x, y, z' do |klass|
  let(:alpha) { double('alpha') }
  let(:beta) { double('beta') }
  subject { klass.new(alpha, beta) }
  context 'alpha delegates' do
    it do
      expect(alpha).to receive(:x).and_return(123)
      expect(subject.x).to eql(123)
    end

    it do
      expect(alpha).to receive(:x).with(1, 2, 3, boo: :who).and_return(123)
      expect(subject.x(1, 2, 3, boo: :who)).to eql(123)
    end
  end

  context 'beta delegates' do
    [ :y, :z ].each do |msg|
      it do
        expect(beta).to receive(msg).and_return(123)
        expect(subject.send(msg)).to eql(123)
      end

      it do
        expect(beta).to receive(msg).with(1, 2, 3, boo: :who).and_return(123)
        expect(subject.send(msg, 1, 2, 3, boo: :who)).to eql(123)
      end
    end
  end
end

describe Object do
  describe '.delegate' do
    klass = Class.new do
      delegate :x, to: :alpha
      delegate :y, :z, to: :beta

      attr_accessor :alpha, :beta

      def initialize a, b
        @alpha = a
        @beta = b
      end
    end

    it_should_behave_like 'delegated x, y, z', klass
  end
  
  describe '.inheritable_attr' do
    let(:klass) do
      Class.new do
        inheritable_attr :alpha, :beta
      end
    end

    it_behaves_like 'inheritable attributes'
  end

  describe '#true?' do
    it { expect(subject.true?).to be(true) }
  end

  describe '#false?' do
    it { expect(subject.false?).to be(false) }
  end


  describe '#skip_unless' do
    subject { 'hey' }

    it { expect(subject.skip_unless(true).upcase).to eql('HEY') }
    it { expect(subject.skip_unless(false).upcase).to eql(subject) }

    it { expect(subject.skip_unless { true }.upcase).to eql('HEY') }
    it { expect(subject.skip_unless { false }.upcase).to eql(subject) }

    it { expect(subject.skip_unless(true) { true }.upcase).to eql('HEY') }
    it { expect(subject.skip_unless(false) { true }.upcase).to eql(subject) }
    it { expect(subject.skip_unless(true) { false }.upcase).to eql(subject) }
    it { expect(subject.skip_unless(false) { false }.upcase).to eql(subject) }

    context 'doubled up' do
      it { expect(subject.skip_unless(true).skip_unless(true).upcase).to eql('HEY') }
      it { expect(subject.skip_unless(true).skip_unless(false).upcase).to eql(subject) }
      it { expect(subject.skip_unless(false).skip_unless(true).upcase).to eql('HEY') }
      it { expect(subject.skip_unless(false).skip_unless(false).upcase).to eql(subject) }
    end

    context 'tripled up' do
      let(:results) do
        { true => {
            true => {true => 'HEY', false => 'hey' },
            false => {true => 'HEY', false => 'hey'}
          },
          false => {
            true => {true => 'HEY', false => 'hey'},
            false => {true => 'hey', false => 'hey'}
          }
        }
      end
      
      [ true, false ].repeated_permutation(3) do |(a, b, c)|
        it "for #{a}, #{b}, #{c}" do
          expect(subject.
                 skip_unless(a).
                 skip_unless(b).
                 skip_unless(c). upcase).to eql(results.dig(a, b, c))
        end
      end
    end
  end

  describe '#skip_when' do
    subject { 'hey' }

    it { expect(subject.skip_when(true).upcase).to eql(subject) }
    it { expect(subject.skip_when(false).upcase).to eql('HEY') }

    it { expect(subject.skip_when { true }.upcase).to eql(subject) }
    it { expect(subject.skip_when { false }.upcase).to eql('HEY') }

    it { expect(subject.skip_when(true) { true }.upcase).to eql(subject) }
    it { expect(subject.skip_when(false) { false }.upcase).to eql('HEY') }
    it { expect(subject.skip_when(false) { true }.upcase).to eql('HEY') }
    it { expect(subject.skip_when(true) { false }.upcase).to eql('HEY') }
    
    context 'doubled up' do
      it { expect(subject.skip_when(true).skip_when(true).upcase).to eql(subject) }
      it { expect(subject.skip_when(true).skip_when(false).upcase).to eql('HEY') }
      it { expect(subject.skip_when(false).skip_when(true).upcase).to eql(subject) }
      it { expect(subject.skip_when(false).skip_when(false).upcase).to eql('HEY') }
    end

    context 'tripled up' do
      let(:results) do
        { true => {
            true => {true => 'hey', false => 'hey' },
            false => {true => 'hey', false => 'HEY'}
          },
          false => {
            true => {true => 'hey', false => 'HEY'},
            false => {true => 'hey', false => 'HEY'}
          }
        }
      end
      
      [ true, false ].repeated_permutation(3) do |(a, b, c)|
        it "for #{a}, #{b}, #{c}" do
          expect(subject.
                 skip_when(a).
                 skip_when(b).
                 skip_when(c).upcase).to eql(results.dig(a, b, c))
        end
      end

      [ true, false ].repeated_permutation(3) do |(a, b, c)|
        it "for #{a}, #{b}, #{c}" do
          expect(subject.
                 skip_when { a }.
                 skip_when { b }.
                 skip_when { c }.upcase).to eql(results.dig(a, b, c))
        end
      end
    end
  end

  describe '#pick' do
    context 'array' do
      subject { [ 2, 3, 4 ] }
      it { expect(subject.pick(1)).to eql([3]) }
      it { expect(subject.pick(0,2)).to eql([2, 4]) }
      it { expect(subject.pick(10)).to eql([nil]) }
    end

    context 'hash' do
      subject { { a: 2, b: 3, c: 4 } }
      it { expect(subject.pick(:b)).to eql([3]) }
      it { expect(subject.pick(:a, :c)).to eql([2, 4]) }
    end
  end

  describe '#pick_attrs' do
    context 'array' do
      subject { [ 2, 3, 4 ] }
      it { expect(subject.pick_attrs(:first)).to eql([2]) }
      it { expect(subject.pick_attrs(:first, :size)).to eql([2, 3]) }
      it { expect { subject.pick_attrs(:boom) }.to raise_error(NoMethodError) }
    end

    context 'hash' do
      subject { { a: 2, b: 3, c: 4 } }
      it { expect(subject.pick_attrs(:keys, :values)).to eql([[:a, :b, :c], [2, 3, 4]]) }
      it { expect{ subject.pick_attrs(:a, :c) }.to raise_error(NoMethodError) }
    end
  end
end

describe Module do
  describe '.delegate' do
    mod = Module.new do
      delegate :x, to: :alpha
      delegate :y, :z, to: :beta

      attr_accessor :alpha, :beta

      def initialize a, b
        @alpha = a
        @beta = b
      end
    end
    klass = Class.new do
      include mod
    end

    it_should_behave_like 'delegated x, y, z', klass
  end

  describe '.mattr_accessor' do
    let(:mod) do
      Module.new do
        mattr_accessor :alpha, :beta
      end
    end

    it { expect { mod.alpha = 123 }.
           to change { mod.alpha }.to(123)
    }
    it { expect { mod.beta = 123 }.
           to change { mod.beta }.to(123)
    }
  end
  
  xdescribe '.inheritable_attr' do
    let(:mod) do
      Module.new do
        inheritable_attr :alpha, :beta
      end
    end
    
    describe 'included in a class' do
      let(:klass) do
        k = Class.new do
        end
        k.include(mod)
        k
      end

      it_behaves_like 'inheritable attributes'

      describe 'that is inherited' do
      end
    end
  end
end

# todo test with any Enumerable
describe Array do
  describe '#permutate_with' do
    describe 'empty array' do
      subject { [] }
      it 'never calls the block' do
        expect do |b|
          subject.permutate_with([ :upcase, :downcase ], &b)
        end.to yield_successive_args()
      end
    end

    describe 'single item' do
      subject { [ 'hello' ] }
      it 'calls the block for every variant' do
        expect do |b|
          subject.permutate_with([ :upcase, :downcase ], &b)
        end.to yield_successive_args([ 'HELLO' ], [ 'hello' ])
      end
    end

    describe 'two items' do
      context 'strings' do
        subject { [ 'foo', 'bar' ] }
        it 'calls the block for every variast of every item' do
          expect do |b|
            subject.permutate_with([ :upcase, :downcase,
                                     lambda { |s| s.capitalize }
                                   ], &b)
          end.to yield_successive_args(["FOO", "BAR"],
                                       ["FOO", "bar"],
                                       ["FOO", "Bar"],
                                       ["foo", "BAR"],
                                       ["foo", "bar"],
                                       ["foo", "Bar"],
                                       ["Foo", "BAR"],
                                       ["Foo", "bar"],
                                       ["Foo", "Bar"])
        end
      end
      
      context 'bools' do
        subject { [ true, true ] }
        it 'calls the block for every variast of every item' do
          expect do |b|
            subject.permutate_with([ :identity, :! ], &b)
          end.to yield_successive_args([true, true],
                                        [true, false],
                                        [false, true],
                                        [false, false])
        end
      end
    end
    
    describe 'many items' do
      context 'bools' do
        subject { [ true, true, true ] }
        it 'calls the block for every variast of every item' do
          expect do |b|
            subject.permutate_with([ :identity, :! ], &b)
          end.to yield_successive_args([true, true, true],
                                       [true, true, false],
                                       [true, false, true],
                                       [true, false, false],
                                       [false, true, true],
                                       [false, true, false],
                                       [false, false, true],
                                       [false, false, false])
        end
      end

      context 'equal number variants' do
        subject { [ 'hello', 'world', 'foo' ] }
        it 'calls the block for every variast of every item' do
          expect do |b|
            subject.permutate_with([ :upcase, :downcase,
                                     lambda { |s| s.capitalize }
                                   ], &b)
          end.to yield_successive_args(["HELLO", "WORLD", "FOO"],
                                       ["HELLO", "WORLD", "foo"],
                                       ["HELLO", "WORLD", "Foo"],
                                       ["HELLO", "world", "FOO"],
                                       ["HELLO", "world", "foo"],
                                       ["HELLO", "world", "Foo"],
                                       ["HELLO", "World", "FOO"],
                                       ["HELLO", "World", "foo"],
                                       ["HELLO", "World", "Foo"],
                                       ["hello", "WORLD", "FOO"],
                                       ["hello", "WORLD", "foo"],
                                       ["hello", "WORLD", "Foo"],
                                       ["hello", "world", "FOO"],
                                       ["hello", "world", "foo"],
                                       ["hello", "world", "Foo"],
                                       ["hello", "World", "FOO"],
                                       ["hello", "World", "foo"],
                                       ["hello", "World", "Foo"],
                                       ["Hello", "WORLD", "FOO"],
                                       ["Hello", "WORLD", "foo"],
                                       ["Hello", "WORLD", "Foo"],
                                       ["Hello", "world", "FOO"],
                                       ["Hello", "world", "foo"],
                                       ["Hello", "world", "Foo"],
                                       ["Hello", "World", "FOO"],
                                       ["Hello", "World", "foo"],
                                       ["Hello", "World", "Foo"])
        end
      end
      
      describe 'with no block' do
        subject { [ 'hello', 'world' ] }
        it 'returns an Enumerator' do
          expect(subject.permutate_with([ :upcase, :downcase ])).
            to be_kind_of(Enumerator)
        end
        
        it 'enumerates every variant of every item' do
          en = subject.each.permutate_with([ :upcase, :downcase ])
          expect(en.next).to eql([ 'HELLO', 'WORLD' ])
          expect(en.next).to eql([ 'HELLO', 'world' ])
          expect(en.next).to eql([ 'hello', 'WORLD' ])
          expect(en.next).to eql([ 'hello', 'world' ])
          expect { en.next }.to raise_error(StopIteration)
        end
      end
    end
  end

  describe '#delete_one!' do
    it { expect([].delete_one!(2)).to eql(nil) }

    let(:arr) { [ 10, 20, 30, 20 ] }
    
    it { expect { arr.delete_one!(20) }.to change { arr }.to([ 10, 30, 20 ]) }
    it { expect { arr.delete_one!(40) }.to_not change { arr } }

    it 'modifies the array' do
      a = %w{a b c a}
      b = a.delete_one!('a')
      expect(a).to eql(%w{b c a})
    end

    it 'returns the item' do
      a = %w{a b c a}
      b = a.delete_one!('a')
      expect(b).to eql('a')
    end

    it 'returns nil if nothing is deleted' do
      a = %w{a b c a}
      b = a.delete_one!('d')
      expect(b).to be(nil)
      expect(a).to eql(%w{a b c a})
    end
  end

  describe '#delete_one' do
    it { expect([].delete_one(:c)).to eql([]) }
    
    it { expect([ 1, 1, 1 ].delete_one(1)).to eql([ 1, 1 ]) }

    it {
      expect(%w{a b c d a b c d}.delete_one(:c)).
      to eql(%w{a b c d a b c d})
    }

    it {
      expect(%w{a b c d a b c d}.delete_one('c')).
      to eql(%w{a b d a b c d})
    }

    it 'returns a new array' do
      a = %w{a b c a}
      b = a.delete_one('a')
      expect(b).to_not equal(a)
      expect(b).to eql(%w{b c a})
    end

    it 'returns the array if nothing is deleted' do
      a = %w{a b c a}
      b = a.delete_one('z')
      expect(b).to equal(a)
    end
  end
end

describe String do
  describe '#blank?' do
    [ '', ' ', '    ', nil ].each do |value|
      it "considers #{value.inspect} blank" do
        expect(value.blank?).to be(true)
      end
    end

    [ 'a', ' 12', '  45', true ].each do |value|
      it "considers #{value.inspect} not be blank" do
        expect(value.blank?).to be(false)
      end
    end
  end

  %w{ space upper lower
      alnum alpha digit xdigit
      cntrl graph print
      punct word ascii
      empty
    }.each do |pred|
    describe "\##{pred}" do
      [ [ '', [ :empty ] ],
        [ " \n\t", [ :space, :ascii ] ],
        [ "abc", [ :lower, :alpha, :alnum, :ascii, :xdigit, :word, :print, :graph ] ],
        [ "ABC", [ :upper, :alpha, :alnum, :ascii, :xdigit, :word, :print, :graph ] ],
        [ "xyz123", [ :alnum, :ascii, :word, :print, :graph ] ],
        [ "ABcd", [ :alpha, :alnum, :xdigit, :ascii, :word, :print, :graph ] ],
        [ "123", [ :digit, :alnum, :xdigit, :ascii, :word, :print, :graph ] ],
        [ "12ab", [ :xdigit, :alnum, :ascii, :word, :print, :graph ] ],
        [ ".!?", [ :punct, :ascii, :print, :graph ] ],
        [ "\n\t\e", [ :cntrl, :ascii ] ]
      ].each do |(input, char_class)|
        if char_class.include?(pred.to_sym)
          instance_eval <<-EOT
          it 'matches #{input.inspect}' do
            expect(input.#{pred}?).to be(true)
          end
EOT
        else
          instance_eval <<-EOT
          it 'does not match #{input.inspect}' do
            expect(input.#{pred}?).to be(false)
          end
EOT
        end
      end
    end
  end
  
  describe 'plural words' do
    examples = {
      'foot' => 'feet',
      'day' => 'days',
      'fey' => 'feys',
      'fry' => 'fries',
      'cringy' => 'cringies',
      'berry' => 'berries',
      'bunch' => 'bunches',
      'thief' => 'thieves',
      'leaf' => 'leaves',
      'life' => 'lives',
      'gif' => 'gifs',
      'five' => 'fives',
      'cat' => 'cats',
      'goose' => 'geese',
      'fish' => 'fish',
      'sharkfish' => 'sharkfish',
      'sheep' => 'sheep',
      'peep' => 'peeps',
      'potato' => 'potatoes',
      'taco' => 'tacos',
      'echo' => 'echoes',
      'choose' => 'chooses',
      'address' => 'addresses',
      'dress' => 'dresses'
    }
    examples.each do |input, output|
      it "\#pluralize converts #{input.inspect} to #{output.inspect}" do
        expect(input.pluralize).to eql(output)
      end
      it "\#pluralize converts #{output.inspect} to #{output.inspect}" do
        expect(output.pluralize).to eql(output)
      end
      it "\#singularize converts #{output.inspect} to #{input.inspect}" do
        expect(output.singularize).to eql(input)
      end
      it "\#singularize converts #{input.inspect} to #{input.inspect}" do
        expect(input.singularize).to eql(input)
      end
    end
  end
  
  describe '#titleize' do
    examples = {
      'hello world' => 'Hello World',
      'hello-world' => 'Hello-World',
      'hello_world' => 'Hello_World',
      'hello World' => 'Hello World',
    }
    examples.each do |input, output|
      it "converts #{input.inspect} to #{output.inspect}" do
        expect(input.titleize).to eql(output)
      end
    end
  end
  
  describe '#camelize' do
    examples =
      Hash[ [ ' ', '-', '_' ].permutation(1).collect { |p|
              [ %w{ hello world }.zip(p).join, 'HelloWorld' ]
            } +
            [ ' ', '-', '_' ].permutation(3).collect { |p|
              [ %w{ hello world foo bar }.zip(p).join, 'HelloWorldFooBar' ]
            } +
            [ [ 'foo', 'Foo' ],
              [ 'hello World', 'HelloWorld' ],
              [ 'hello-World', 'HelloWorld' ],
              [ 'hello-world', 'HelloWorld' ],
              [ 'Hello/World', 'Hello::World' ],
              [ 'hello/good/world', 'Hello::Good::World' ],
              #[ 'Hello/World', 'Hello/World' ],
              [ 'hello - world', 'Hello-World' ],
              [ 'hello _ world', 'Hello_World' ],
              [ 'hello / world', 'Hello/World' ],
              [ 'Hello / World', 'Hello/World' ],
              [ 'HelloWorld', 'HelloWorld' ],
              [ 'TheFooBar', 'TheFooBar' ],
              [ 'HELLOworld', 'HELLOworld' ],
              [ 'HELLO123', 'Hello123' ],
              [ 'HELLO world', 'HelloWorld' ],
              [ 'HELLO WORld', 'HelloWORld' ]
            ]
          ]
    
    examples.each do |input, output|
      it "converts #{input.inspect} to #{output.inspect}" do
        expect(input.camelize).to eql(output)
      end
    end
  end

  describe '#decamelize' do
    examples =
      Hash[ [
             [ 'HelloWorld', 'hello world' ],
             [ 'hello-world', 'hello world' ],
             [ 'hello_world', 'hello world' ],
             [ 'Hello/World', 'hello/world' ],
             [ 'Hello / World', 'hello / world' ],
             [ 'hello/world', 'hello/world' ],
             [ 'Hello::World', 'hello/world' ],
             [ 'Hello :: World', 'hello / world' ],
             [ 'hello::world', 'hello/world' ],
             [ 'HELLOworld', 'helloworld' ],
             [ 'HELLOworld-hello', 'helloworld hello' ]
             ]
          ]
    
    examples.each do |input, output|
      it "converts #{input.inspect} to #{output.inspect}" do
        expect(input.decamelize).to eql(output)
      end
    end
  end

  describe '#hyphenate' do
    examples =
      Hash[ [
             [ 'HelloWorld', 'hello-world' ],
             [ 'hello-world', 'hello-world' ],
             [ 'hello_world', 'hello-world' ],
             [ 'hello world', 'hello-world' ],
             ]
          ]
    
    examples.each do |input, output|
      it "converts #{input.inspect} to #{output.inspect}" do
        expect(input.hyphenate).to eql(output)
      end
    end
  end

  describe '#underscore' do
    examples =
      Hash[ [
             [ 'HelloWorld', 'hello_world' ],
             [ 'hello-world', 'hello_world' ],
             [ 'hello_world', 'hello_world' ],
             [ 'hello world', 'hello_world' ],
             ]
          ]
    
    examples.each do |input, output|
      it "converts #{input.inspect} to #{output.inspect}" do
        expect(input.underscore).to eql(output)
      end
    end
  end

  describe '#to_bool' do
    %w{ t true y yes Yes YEs 1 1111 1234 }.each do |value|
      it "truths #{value.inspect}" do
        expect(value.to_bool).to be(true)
      end
    end
    %w{ f false n no noooo No NOOO 0 0000 }.each do |value|
      it "falsifies #{value.inspect}" do
        expect(value.to_bool).to be(false)
      end
    end
  end

  describe '#to_proc' do
    subject { 'Int: %i Float: %.1f'.to_proc }

    it { expect(subject).to be_kind_of(Proc) }

    it 'formats the arguments' do
      expect(subject.(123, 456)).to eql('Int: 123 Float: 456.0')
    end
    
    it 'deconstructs arguments in an array' do
      expect(subject.([123, 456])).to eql('Int: 123 Float: 456.0')
    end
    
    it 'works over enumerables' do
      expect([ [ 1, 2 ], [ 3, 4 ] ].collect(&'%i %.1f')).to eql([ '1 2.0', '3 4.0' ])
    end
  end

  describe '#cycled' do
    it { expect('foo'.cycled(10)).to eql('foofoofoof') }
    it { expect('foo'.cycled(0.5)).to eql('f') }
    it { expect('foo'.cycled(3)).to eql('foo') }
    it { expect('foo'.cycled(4)).to eql('foof') }
    it { expect(''.cycled(4)).to eql('') }
  end
  
  describe '#cycle_visually' do
    it { expect("\e[31;43mfoo".cycle_visually(10)).to eql("\e[31;43mfoo\e[31;43mfoo\e[31;43mfoo\e[31;43mf\e[0m") }
    it { expect("\e[31;43mfoo".cycle_visually(1.5)).to eql("\e[31;43mfo\e[0m") }
    it { expect("\e[31;43mfoo".cycle_visually(0.75)).to eql("\e[31;43mf\e[0m") }
    it { expect("\e[31;43mfoo".cycle_visually(0.45)).to eql("\e[31;43mf\e[0m") }
    it { expect("\e[31;43mfoo".cycle_visually(3)).to eql("\e[31;43mfoo\e[0m") }
    it { expect("\e[31;43mfoo".cycle_visually(4)).to eql("\e[31;43mfoo\e[31;43mf\e[0m") }
    it { expect("".cycle_visually(4)).to eql("") }
  end
  
  describe '#truncate' do
    [ [ '', 5, '', 0 ],
      [ "hello", 10, "hello", 5 ],
      [ "hello", 2, "he" ],
      [ "hello", 5, "hello" ],
      [ "\e[31;1mhello\e[0m", 10, "\e[31;1mhello\e[0m", 5 ],
      [ "\e[31;1mhello\e[0m", 2, "\e[31;1mhe\e[0m" ],
      [ "\e[31;1mhello\e[0m", 5, "\e[31;1mhello\e[0m" ],
      [ "\e[31mh\e[0mello", 2, "\e[31mh\e[0me" ],
      [ "\e[31;0mhello", 2, "\e[31;0mhe" ],
      [ "\e[31mh\e[1;0mello", 2, "\e[31mh\e[1;0me" ],
      [ "\e[31mh\e[1;0000mello", 2, "\e[31mh\e[1;0000me" ],
    ].each do |(input, isize, output, osize)|
      it "truncates #{input.inspect} as #{output.inspect}" do
        expect(input.truncate(isize)).to eql(output)
      end
      it "limits to the printable screen size" do
        expect(input.truncate(isize).screen_size).to eql(osize || isize)
      end
    end
  end

  describe '#center_visually' do
    [ [ '', 5, '     ' ],
      [ "hello", 10, "  hello   " ],
      [ "hello", 2, "hello", 5 ],
      [ "hello", 5, "hello" ],
      [ "\e[31;1mhello\e[0m", 10, "  \e[31;1mhello\e[0m   " ],
      [ "\e[31;1mhello\e[0m", 2, "\e[31;1mhello\e[0m", 5 ],
      [ "\e[31;1mhello\e[0m", 5, "\e[31;1mhello\e[0m" ],
    ].each do |(input, isize, output, osize)|
      context "#{input.inspect} at #{isize}" do
        subject { input.center_visually(isize) }
        
        it "centers as #{output.inspect}" do
          expect(subject).to eql(output)
        end
        it "limits to the printable screen size" do
          expect(subject.screen_size).to eql(osize || isize)
        end
      end
    end

    it { expect(''.center_visually(10, 'xy')).to eql('xyxyxyxyxy') }
    it { expect('hello'.center_visually(10, 'xy')).to eql('xyhelloyxy') }
    it { expect('hello'.center_visually(10, 'x')).to eql('xxhelloxxx') }
    it { expect('hello'.center_visually(10, 'xyz')).to eql('xyhelloyzx') }
  end

  describe '#ljust_visually' do
    [ [ '', 5, '     ' ],
      [ "hello", 10, "hello     " ],
      [ "hello", 2, "hello", 5 ],
      [ "hello", 5, "hello" ],
      [ "\e[31;1mhello\e[0m", 10, "\e[31;1mhello\e[0m     " ],
      [ "\e[31;1mhello\e[0m", 2, "\e[31;1mhello\e[0m", 5 ],
      [ "\e[31;1mhello\e[0m", 5, "\e[31;1mhello\e[0m" ],
    ].each do |(input, isize, output, osize)|
      context "#{input.inspect} at #{isize}" do
        subject { input.ljust_visually(isize) }
        
        it "pads as #{output.inspect}" do
          expect(subject).to eql(output)
        end
        it "limits to the printable screen size" do
          expect(subject.screen_size).to eql(osize || isize)
        end
      end
    end

    it { expect(''.ljust_visually(10, 'xy')).to eql('xyxyxyxyxy') }
    it { expect('hello'.ljust_visually(10, 'xy')).to eql('helloyxyxy') }
    it { expect('hello'.ljust_visually(10, 'x')).to eql('helloxxxxx') }
    it { expect('hello'.ljust_visually(10, 'xyz')).to eql('hellozxyzx') }
  end

  describe '#rjust_visually' do
    [ [ '', 5, '     ' ],
      [ "hello", 10, "     hello" ],
      [ "hello", 2, "hello", 5 ],
      [ "hello", 5, "hello" ],
      [ "\e[31;1mhello\e[0m", 10, "     \e[31;1mhello\e[0m" ],
      [ "\e[31;1mhello\e[0m", 2, "\e[31;1mhello\e[0m", 5 ],
      [ "\e[31;1mhello\e[0m", 5, "\e[31;1mhello\e[0m" ],
    ].each do |(input, isize, output, osize)|
      context "#{input.inspect} at #{isize}" do
        subject { input.rjust_visually(isize) }
        
        it "pads as #{output.inspect}" do
          expect(input.rjust_visually(isize)).to eql(output)
        end
        it "limits to the printable screen size" do
          expect(input.rjust_visually(isize).screen_size).to eql(osize || isize)
        end
      end
    end

    it { expect(''.rjust_visually(10, 'xy')).to eql('xyxyxyxyxy') }
    it { expect('hello'.rjust_visually(10, 'xy')).to eql('xyxyxhello') }
    it { expect('hello'.rjust_visually(10, 'x')).to eql('xxxxxhello') }
    it { expect('hello'.rjust_visually(10, 'xyz')).to eql('xyzxyhello') }
  end
end

describe Enumerable do
  describe '#pluck' do
    context 'arrays' do
      subject { 9.times.each_slice(3).to_a }
      it { expect(subject.pluck(0)).to eql([[0],[3],[6]]) }
      it { expect(subject.pluck(0, 2)).to eql([[0,2],[3,5],[6,8]]) }
      it { expect(subject.pluck(0, 2, 10)).to eql([[0,2,nil],[3,5,nil],[6,8,nil]]) }
      it { expect(subject.pluck()).to eql([[],[],[]]) }
    end
    context 'hashes' do
      subject { [ { a: 1, b: 2, c: 3 },
                  { a: 3, b: 4, c: 5 }
                ] }
      it { expect(subject.pluck(:b)).to eql([[2],[4]]) }
      it { expect(subject.pluck(:a, :c)).to eql([[1,3],[3,5]]) }
      it { expect(subject.pluck(:a, :c, :d)).to eql([[1,3,nil],[3,5,nil]]) }
      it { expect(subject.pluck()).to eql([[],[]]) }
    end
  end
  
  describe '#pluck_attrs' do
    context 'structs' do
      let(:struct) { Struct.new(:a, :b, :c) }
      subject { [ struct.new(1, 2, 3),
                  struct.new(3, 4, 5)
                ] }
      it { expect(subject.pluck_attrs(:b)).to eql([[2],[4]]) }
      it { expect(subject.pluck_attrs(:a, :c)).to eql([[1,3],[3,5]]) }
      it { expect(subject.pluck_attrs()).to eql([[],[]]) }
    end
  end

  describe '#aggregate' do
    context 'two zipped ranges' do
      subject { (0..5).each.zip(10..15) }
      it { expect(subject.aggregate([0, 0], &:+)).to eql([15, 75]) }
      it do
        expect(subject.aggregate([[], []], &:<<)).
        to eql([[0,1,2,3,4,5],
                [10,11,12,13,14,15]])
      end
    end
  end

  describe '#nth' do
    subject { 5.times.each }
    5.times do |n|
      it { expect(subject.nth(n)).to be(subject.drop(n).first) }
      it { expect(subject.nth(n, 2)).to eql(subject.drop(n).first(2)) }
    end
  end

  describe '#second' do
    subject { 5.times.each }
    it { expect(subject.second).to eql(1) }
    it { expect(subject.second(1)).to eql([1]) }
    it { expect(subject.second(2)).to eql([1, 2]) }
  end

  describe '#third' do
    subject { 5.times.each }
    it { expect(subject.third).to eql(2) }
    it { expect(subject.third(1)).to eql([2]) }
    it { expect(subject.third(2)).to eql([2, 3]) }
  end

  describe '#fourth' do
    subject { 5.times.each }
    it { expect(subject.fourth).to eql(3) }
    it { expect(subject.fourth(1)).to eql([3]) }
    it { expect(subject.fourth(2)).to eql([3,4]) }
  end

  describe '#skip_unless' do
    subject { 10.times.each }
    let(:evens) { subject.select(&:even?) }
    
    it { expect(subject.skip_unless(true).select(&:even?)).to eql(evens) }
    it { expect(subject.skip_unless(false).select(&:even?)).to eql(subject) }

    it { expect(subject.skip_unless { |x| x.size == 10 }.select(&:even?)).to eql(evens) }
    it { expect(subject.skip_unless { |x| x.size < 10 }.select(&:even?)).to eql(subject) }

    it { expect(subject.skip_unless(true) { |x| x.size == 10 }.select(&:even?)).to eql(evens) }
    it { expect(subject.skip_unless(false) { |x| x.size == 10 }.select(&:even?)).to eql(subject) }
  end

  describe '#skip_when' do
    subject { 10.times.each }
    let(:evens) { subject.select(&:even?) }
    
    it { expect(subject.skip_when(false).select(&:even?)).to eql(evens) }
    it { expect(subject.skip_when(true).select(&:even?)).to eql(subject) }

    it { expect(subject.skip_when { |x| x.size < 10 }.select(&:even?)).to eql(evens) }
    it { expect(subject.skip_when { |x| x.size == 10 }.select(&:even?)).to eql(subject) }

    it { expect(subject.skip_when(false) { |x| x.size < 10 }.select(&:even?)).to eql(evens) }
    it { expect(subject.skip_when(true) { |x| x.size < 10 }.select(&:even?)).to eql(evens) }
    it { expect(subject.skip_when(true) { |x| x.size <= 10 }.select(&:even?)).to eql(subject) }
    it { expect(subject.skip_when(true) { |x| x.equal?(subject) }.select(&:even?)).to eql(subject) }
  end
  
end

describe Proc do
  describe '#not' do
    subject { lambda { |a| a } }
    it { expect(subject.not.call(true)).to eql(false) }
    it { expect(subject.not.call(false)).to eql(true) }
  end

  describe '#~' do
    subject { lambda { |a| a } }
    it { expect((~subject).call(true)).to eql(false) }
    it { expect((~subject).call(false)).to eql(true) }
  end
end

describe Range do
  [ [ (0..10), [ 0, 11 ] ],
    [ (0...10), [ 0, 10 ] ],
    [ (-5..0), [ -5, 6 ] ],
    [ (-5...0), [ -5, 5 ] ],
    [ (0..-5), [ -5, 6 ] ],
    [ (0...-5), [ -5, 5 ] ],
  ].each do |(r, idx)|
    it "#{r} -> #{idx.inspect}" do
      expect(r.to_array_index).to eql(idx)
    end
  end
end

describe Integer do
  describe '#count_bits' do
    it { expect { -1.count_bits }.to raise_error(ArgumentError) }

    [ [ 0xFFFFFFFF, 32 ],
      [ 1, 1 ],
      [ 3, 2 ],
      [ 0x100, 1 ],
      [ 0xFF00, 8 ]
    ].each do |(input, output)|
      it "counts #{output} bits for 0x#{input.to_s(16)} (#{input.to_s(2)})" do
        expect(input.count_bits).to eql(output)
      end
    end
  end
  
  describe '#revbits' do
    #it { expect(-1.count_bits).to raise_error(ArgumentError) }

    [ [ 0xFFFFFFFF, 0xFFFFFFFF ],
      [ 1, 0x80000000 ],
      [ 3, 0xC0000000 ],
      [ 0x100, 0x800000 ],
      [ 0xFF00, 0xFF0000 ]
    ].each do |(input, output)|
      it "reverses 0x#{input.to_s(16)} into 0x#{output.to_s(16)}" do
        expect(input.revbits).to eql(output)
      end
    end

    [ [ 0xFFFFFFFF, 0xFFFF ],
      [ 1, 0x8000 ],
      [ 3, 0xC000 ],
      [ 0x100, 0x80 ],
      [ 0xFF00, 0xFF ]
    ].each do |(input, output)|
      it "reverses 0x#{input.to_s(16)} to 0x#{output.to_s(16)} within 16 bits" do
        expect(input.revbits(16)).to eql(output)
      end
    end
  end

  describe '#nth_byte' do
    8.times do |n|
      output = (n + 1)*16 + (n+1)
      it "returns 0x#{output.to_s(16)} for byte #{n}" do
        expect(0x8877665544332211.nth_byte(n)).to eql(output)
      end
    end
    it "returns 0 for byte 8" do
      expect(0x8877665544332211.nth_byte(8)).to eql(0)
    end
  end

  describe '#to_bitmask' do
    it { expect { -1.to_bitmask }.to raise_error(ArgumentError) }
    it { expect { 0.to_bitmask }.to raise_error(ArgumentError) }
    
    [ [ 1, 1 ],
      [ 7, 7 ],
      [ 6, 7 ],
      [ 15, 0xF ],
      [ 16, 0x1F ],
      [ 31, 0x1F ],
      [ 32, 0x3F ],
      [ 255, 0xFF ],
      [ 256, 0x1FF ],
      [ 0x10000000, 0x1FFFFFFF ],
      [ 0x10203040, 0x1FFFFFFF ]
    ].each do |(input, output)|
      it "masks 0x#{input.to_s(16)} with 0x#{output.to_s(16)}" do
        expect(input.to_bitmask).to eql(output)
      end
    end
  end
end
