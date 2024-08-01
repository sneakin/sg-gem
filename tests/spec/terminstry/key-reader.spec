# -*- coding: utf-8 -*-
require 'sg/terminstry/decoder'
require 'sg/terminstry/key-reader'
require 'sg/terminstry/drawing'
require 'sg/terminstry/terminals'
using SG::Ext

describe SG::Terminstry::KeyReader do
  let(:pipe) { IO.pipe }
  let(:in_io) { pipe[0] }
  let(:out_io) { pipe[1] }
  let(:decoder_class) { SG::Terminstry::Decoder::VT100 }
  let(:decoder) { decoder_class.new(in_io.each_char) }
  subject { described_class.new(decoder) }
  after do
    in_io.close
    out_io.close
  end

  describe 'complete sequences' do
    let(:cases) do
      [ [ "h", [ described_class::Key.new('h') ] ],
        [ "😎", [ described_class::Key.new('😎') ] ],
        [ "\eh", [ described_class::Key.new('h', described_class::Key::ALT) ] ],
        [ "\e[0m", nil ],
        [ "\e[34;45;1m", nil ],
        [ "\eOP", [ described_class::Key.new(:F1) ] ],
      ]
    end
    
    describe '#read' do
      it do
        cases.each do |(input, keys)|
          next unless keys
          out_io.write(input)
          expect(subject.read(keys.size)).to be_eql(keys)
        end
      end
    end
  end

  describe 'with 8 bit codes' do
    context 'CSI' do
      subject { described_class.new(decoder_class.new("\x9B34mhey")) }
      it { expect(subject.read(1)).to eql([ described_class::Key.new("h") ]) }
    end
    context 'OSC' do
      subject { described_class.new(decoder_class.new("\x9Dhey\x9C")) }
      it { expect(subject.read(1)).to eql([]) }
    end
    context 'PM' do
      subject { described_class.new(decoder_class.new("\x9Ehey\x9C")) }
      it { expect(subject.read(1)).to eql([]) }
    end
  end
  
  describe '#read(1)' do
    context 'ASCII' do
      it 'decodes into itself' do
        128.times { |n|
          c = n.chr
          next if c == "\e"
          out_io.write(c)
          expect(subject.read(1)).
          to eql([ described_class::Key.new(c,
                              (n < 32 ? described_class::Key::CONTROL : 0) |
                              (c =~ /\A[A-Z]+\Z/ ? described_class::Key::SHIFT : 0)) ])
        }          
      end
    end
    
    context 'arrow key codes' do
      before do
        out_io.write("\e[A\e[B\e[C\e[D")
      end

      it "decodes into a named key" do
        expect(subject.read(1)).to eql([ described_class::Key.new(:up) ])
        expect(subject.read(1)).to eql([ described_class::Key.new(:down) ])
        expect(subject.read(1)).to eql([ described_class::Key.new(:right) ])
        expect(subject.read(1)).to eql([ described_class::Key.new(:left) ])
      end
    end
  end
end
