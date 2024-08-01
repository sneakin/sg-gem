# -*- coding: utf-8 -*-
require 'sg/terminstry/decoder'
require 'sg/terminstry/drawing'
require 'sg/terminstry/terminals'
require 'sg/terminstry/key-reader'
using SG::Ext

describe SG::Terminstry::Decoder::VT100 do
  let(:pipe) { IO.pipe }
  let(:in_io) { pipe[0] }
  let(:out_io) { pipe[1] }
  subject { described_class.new(in_io.each_char) }
  after do
    in_io.close
    out_io.close
  end

  describe 'complete sequences' do
    let(:cases) do
      [ [ "h", [ described_class::Key.new("h") ] ],
        [ "😎", [ described_class::Key.new("😎") ] ],
        [ "\eh", [ described_class::EscapeSeq.new('h') ] ],
        [ "\e[0m", [ described_class::EscapeSeq.new('m', [ 0 ], prefix: '[') ] ],
        [ "\e[34;45;1m", [ described_class::EscapeSeq.new('m', [ 34, 45, 1 ], prefix: '[') ] ],
        [ "\eOP", [ described_class::EscapeSeq.new('P', prefix: 'O') ] ],
      ]
    end
    
    describe '#next' do
      it do
        cases.each do |(input, output)|
          out_io.write(input)
          expect(subject.next).to be_eql(output[0])
        end
      end
    end
  end

  describe 'with 8 bit codes' do
    context 'CSI' do
      subject { described_class.new("\x9B34mhey") }
      it { expect(subject.next).to eql(described_class::EscapeSeq.new('m', [ 34 ], prefix: '[')) }
    end
    context 'OSC' do
      subject { described_class.new("\x9Dhey\x9C") }
      it { expect(subject.next).to eql(described_class::EscapeSeq.new("\e\\", [ "hey" ], prefix: "]")) }
    end
    context 'PM' do
      subject { described_class.new("\x9Ehey\x9C") }
      it { expect(subject.next).to eql(described_class::EscapeSeq.new("\e\\", [ "hey" ], prefix: "^")) }
    end
  end
  
  describe 'roundtrip of tabbox' do
    let(:tty) { SG::Terminstry::Terminals::XTerm.new }
    let(:tb) { SG::Terminstry::Drawing.tabbox('Hello', 'World', tty: tty) }
    
    before do
      out_io.write(tb)
      out_io.close
    end
    
    it { expect(subject.each.collect(&:to_s).join).to eql(tb) }
  end

  describe '#key_name' do
    context 'ASCII' do
      it 'decodes into itself' do
        128.times { |n|
          c = n.chr
          expect(subject.key_name(described_class::Key.new(c))).to eql(c)
        }          
      end
    end
    
    context 'arrow key codes' do
      before do
        out_io.write("\e[A\e[B\e[C\e[D")
      end

      it "decodes into a named key" do
        expect(subject.key_name(subject.next)).to eql(:up)
        expect(subject.key_name(subject.next)).to eql(:down)
        expect(subject.key_name(subject.next)).to eql(:right)
        expect(subject.key_name(subject.next)).to eql(:left)
      end
    end
  end

  describe '#read_key' do
    context 'ASCII' do
      it 'decodes into KeyReader::Key of the character' do
        128.times { |n|
          c = n.chr
          next if c == "\e"
          out_io.write(c)
          expect(subject.read_key).
          to eql(SG::Terminstry::KeyReader::Key.new(c,
                                 (n < 32 ? SG::Terminstry::KeyReader::Key::CONTROL : 0) |
                                 (c =~ /\A[A-Z]+\Z/ ? SG::Terminstry::KeyReader::Key::SHIFT : 0)))
        }          
      end
    end
    
    context 'arrow key codes' do
      before do
        out_io.write("\e[A\e[B\e[C\e[D")
      end

      it "decodes into a named key" do
        expect(subject.read_key).to eql(SG::Terminstry::KeyReader::Key.new(:up))
        expect(subject.read_key).to eql(SG::Terminstry::KeyReader::Key.new(:down))
        expect(subject.read_key).to eql(SG::Terminstry::KeyReader::Key.new(:right))
        expect(subject.read_key).to eql(SG::Terminstry::KeyReader::Key.new(:left))
      end
    end
  end
end
