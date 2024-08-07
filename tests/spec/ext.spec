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

    describe 'many items' do
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
end
