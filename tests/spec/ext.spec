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

describe Object do
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
  
  describe '#pluralize' do
    Examples = {
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
      'echo' => 'echoes'
    }
    Examples.each do |input, output|
      it "converts #{input.inspect} to #{output.inspect}" do
        expect(input.pluralize).to eql(output)
      end
    end
  end
  
  describe '#titleize' do
    Examples = {
      'hello world' => 'Hello World',
      'hello-world' => 'Hello-World',
      'hello_world' => 'Hello_World',
      'hello World' => 'Hello World',
    }
    Examples.each do |input, output|
      it "converts #{input.inspect} to #{output.inspect}" do
        expect(input.titleize).to eql(output)
      end
    end
  end
  
  describe '#camelize' do
    Examples =
      Hash[ [ ' ', '-', '_' ].permutation(1).collect { |p|
              [ %w{ hello world }.zip(p).join, 'HelloWorld' ]
            } +
            [ ' ', '-', '_' ].permutation(3).collect { |p|
              [ %w{ hello world foo bar }.zip(p).join, 'HelloWorldFooBar' ]
            } +
            [ [ 'foo', 'Foo' ],
              [ 'hello World', 'HelloWorld' ],
              [ 'hello-World', 'HelloWorld' ]
            ]
          ]
    
    Examples.each do |input, output|
      it "converts #{input.inspect} to #{output.inspect}" do
        expect(input.camelize).to eql(output)
      end
    end
  end

  describe '#decamelize' do
    Examples =
      Hash[ [
             [ 'HelloWorld', 'hello world' ],
             [ 'hello-world', 'hello world' ],
             [ 'hello_world', 'hello world' ],
             ]
          ]
    
    Examples.each do |input, output|
      it "converts #{input.inspect} to #{output.inspect}" do
        expect(input.decamelize).to eql(output)
      end
    end
  end

  describe '#hyphenate' do
    Examples =
      Hash[ [
             [ 'HelloWorld', 'hello-world' ],
             [ 'hello-world', 'hello-world' ],
             [ 'hello_world', 'hello-world' ],
             ]
          ]
    
    Examples.each do |input, output|
      it "converts #{input.inspect} to #{output.inspect}" do
        expect(input.hyphenate).to eql(output)
      end
    end
  end

  describe '#underscore' do
    Examples =
      Hash[ [
             [ 'HelloWorld', 'hello_world' ],
             [ 'hello-world', 'hello_world' ],
             [ 'hello_world', 'hello_world' ],
             ]
          ]
    
    Examples.each do |input, output|
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
    it { expect(subject.skip_when(true) { |x| x.size < 10 }.select(&:even?)).to eql(subject) }
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
