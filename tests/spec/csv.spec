require 'sg/ext'
using SG::Ext

require 'sg/csv'

describe SG::CSV do
  describe 'default separators' do
    describe '.read' do
      describe 'reading algebra-rules.csv' do
        let(:test_data) { Pathname.new(__FILE__).parent.join('algebra-rules.csv') }

        describe 'with no block' do
          before do
            test_data.open {subject.read(_1) }
          end

          it 'read headers' do
            expect(subject.headers).to eql(%w{ Input Output })
          end
          it 'populated entries' do
            expect(subject.entries.size).to_not eql(0)
          end
          it 'only read two fields' do
            expect(subject.entries.all? { _1.size == 2 }).to be(true)
          end
          it {
            expect{ test_data.open { |io| subject.read(io) { |e| e } } }.
            to change(subject, :size)
          }
        end

        describe 'with a block'  do
          it {
            expect{ test_data.open { |io| subject.read(io, keep: false) { |e| e } } }.
            to_not change(subject, :size)
          }
          it {
            expect{ test_data.open { |io| subject.read(io, keep: true) { |e| e } } }.
            to change(subject, :size)
          }
          it 'yields each entry' do
            ents = []
            test_data.open do |io|
              subject.read(io) do |*fields|
                expect(fields.size).to eql(2)
                ents << fields
              end
            end
            expect(ents.size).to_not eql(0)
          end
          describe 'as a hash' do
            it 'yields each entry as a hash' do
              test_data.open do |io|
                subject.read(io, as_hash: true) do |fields|
                  expect(fields.keys).to eql(subject.headers)
                end
              end
            end
          end
        end
      end
    end
    
    describe '#split_line' do
      [ [ 'hello', [ 'hello' ] ],
        [ 'hello,world', [ 'hello', 'world' ] ],
        [ 'hello,"big world",good', [ 'hello', 'big world', 'good' ] ],
        [ "hello,'big world',good", [ 'hello', 'big world', 'good' ] ],
        [ "hello,'big world,good", SG::CSV::UnterminanedQuoteError ],
        [ "hello,world,\"good,time\",boom\",who\",wow", [ 'hello', 'world', 'good,time', 'boom"', 'who"', 'wow' ] ],
        [ 'a,b,c#d,e,f', [ 'a', 'b', 'c#d', 'e', 'f' ] ],
        [ '     ,    what,in    # tarnation,   is this',
          [ '     ', '    what', 'in    # tarnation', '   is this' ] ],
        [ 'hey\"big,big,world",bye,\\"bye",foo',
          [ 'hey\"big', 'big', 'world"', 'bye', '\\"bye"', 'foo' ] ],
        [ 'hey"big,big,world",bye,"bye,\"foo\""',
          [ 'hey"big', 'big', 'world"', 'bye', 'bye,"foo"' ] ],
        [ 'hey\nworld,"hello\n\tworld\x23",foo',
          [ 'hey\nworld', "hello\n\tworld\\x23", 'foo' ] ],
        [ 'bye,goodbye,"Farewell,,"', [ 'bye', 'goodbye', 'Farewell,,' ] ]
      ].each do |(input, output)|
        if Class === output
          it "raises #{output} for #{input.inspect}" do
            expect { subject.split_line(input, line_num: 12) }.to raise_error(output)
          end
        else
          it "splits #{input.inspect} into #{output.inspect}" do
            expect(subject.split_line(input)).to eql(output)
          end
        end
      end
    end
  end

  describe 'with striping' do
    subject { described_class.new(strip: true) }
    
    describe '#split_line' do
      [ [ "hello,world,\"good,time\",boom\",who\",wow",
          [ 'hello', 'world', 'good,time', 'boom"', 'who"', 'wow' ] ],
        [ '     ,    what,in    # tarnation,   is this',
          [ '', 'what', 'in    # tarnation', 'is this' ] ],
      ].each do |(input, output)|
        if Class === output
          it "raises #{output} for #{input.inspect}" do
            expect { subject.split_line(input) }.to raise_error(output)
          end
        else
          it "splits #{input.inspect} into #{output.inspect}" do
            expect(subject.split_line(input)).to eql(output)
          end
        end
      end
    end
  end

  describe 'with all options tweaked for multiline' do
    subject { described_class.new(record_separator: "\f",
                                  field_separator: "\n",
                                  quotes: "\"!",
                                  strip: true,
                                  comments: ';;') }
    let(:data) do
      <<-EOT
Key
Value
Comment
hello
hello world ;; yolo
hello ;; yolo
hello world

;; or here
bye
goodbye
!Farewell
cruel
world!
EOT
    end

    describe 'read it' do
      before do
        expect { subject.read(data) }.to change(subject, :size).by(3)
      end
      
      it { expect(subject.headers).to eql(%w{ Key Value Comment }) }
      it { expect(subject.entries[0]).to eql([ 'hello', 'hello world']) }
      it { expect(subject.entries[1]).to eql([ 'hello']) }
      it { expect(subject.entries[2]).to eql([ 'bye', 'goodbye', "Farewell\ncruel\nworld"]) }
    end
  end

  describe 'with all options tweaked for one line' do
    subject { described_class.new(record_separator: "\t",
                                  field_separator: "!",
                                  quotes: "\"",
                                  strip: true) }
    let(:data) do
      <<-EOT.chomp
Key!Value!Comment	hello!hello world	bye!goodbye!"Farewell!!"!more	bye!goodbye!"Farewell!!"
EOT
    end

    describe 'read it' do
      before do
        expect { subject.read(data) }.to change(subject, :size).by(3)
      end
      
      it { expect(subject.headers).to eql(%w{ Key Value Comment }) }
      it { expect(subject.entries[0]).to eql([ 'hello', 'hello world']) }
      it { expect(subject.entries[1]).to eql([ 'bye', 'goodbye', 'Farewell!!', 'more']) }
      it { expect(subject.entries[2]).to eql([ 'bye', 'goodbye', 'Farewell!!']) }
    end

    describe '.#split_line' do
      it do
        expect(subject.split_line('bye!goodbye!"Farewell!!"')).
          to eql([ 'bye', 'goodbye', 'Farewell!!'])
      end
    end
  end
end
