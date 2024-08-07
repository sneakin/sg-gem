#!/usr/bin/env -S ruby -W:no-experimental
# -*- coding: utf-8 -*-
require 'bundler/setup'
require 'io/console'
require 'sg/ext'
using SG::Ext

class SG::TablePrinter
  class Column
    attr_accessor :title, :width, :strategy, :formatter, :alignment
    attr_accessor :real_width

    def initialize title: nil, strategy: nil, width: nil, formatter: nil, align: nil
      @title = title
      @strategy = strategy
      @width = width
      @alignment = align
      @formatter = (formatter || :to_s).to_proc
    end

    def format value, align: true
      v = formatter.call(value)
      if align
        align(v)
      else
        v
      end
    end

    def align v, align: alignment, width: real_width
      s = (v || '').truncate(width)
      if width && s.size < width
        case align
        when :center then s = s.center(width)
        when :right then s = s.rjust(width)
        else s = s.ljust(width)
        end
      end
      s
    end
  end

  class Decorator
    None = {
      row: { leader: '', separator: ' ', finalizer: '' },
      #bar: { filler: ' ', leader: '', separator: ' ', finalizer: '' },
      #top_bar: { filler: ' ', leader: '', separator: ' ', finalizer: '' },
      #bottom_bar: { filler: ' ', leader: '', separator: ' ', finalizer: '' }
    }
    Ascii = {
      row: { leader: '| ', separator: ' | ', finalizer: ' |' },
      bar: { filler: '-', leader: '+-', separator: '-+-', finalizer: '-+' },
      top_bar: { filler: '-', leader: '+-', separator: '-+-', finalizer: '-+' },
      bottom_bar: { filler: '-', leader: '+-', separator: '-+-', finalizer: '-+' }
    }
    Box = {
      row: { leader: '│ ', separator: ' │ ', finalizer: ' │' },
      bar: { filler: '─', leader: '├─', separator: '─┼─', finalizer: '─┤' },
      top_bar: { filler: '─', leader: '┌─', separator: '─┬─', finalizer: '─┐' },
      bottom_bar: { filler: '─', leader: '└─', separator: '─┴─', finalizer: '─┘' }
    }

    Styles = {
      none: None,
      ascii: Ascii,
      box: Box
    }

    attr_reader :decor

    def initialize decor = nil
      @decor = case decor
               when String then
                 Styles.fetch(decor.underscore.to_sym, Box)
               when Symbol then
                 Styles.fetch(decor)
               when nil then Box
               else decor
               end
    end
    
    def [] style, place = nil
      if place
        decor.dig(style, place)
      else
        decor[style]
      end
    end

    def decor_width style, columns
      decor[style] => { leader:, separator: , finalizer: }
      leader.size + separator.size * columns + finalizer.size
    end
  end

  attr_reader :columns, :io, :decorator
  
  def initialize io: $stdout, decorator: nil
    @columns = []
    @io = io
    @decorator = decorator || Decorator.new
  end

  def add_column **opts
    @columns << Column.new(**opts)
    self
  end

  def print data, width: nil, resize: true
    resize_columns(data, full_width: width) if resize
    print_bar(:top_bar)
    print_headers
    print_bar(:bar)
    data.each do |row|
      print_row(row)
    end
    print_bar(:bottom_bar)
  end

  def print_row row
    decorator[:row] => { leader:, separator:, finalizer: }
    io.write(leader)
    columns.each_with_index do |col, n|
      io.write(col.format(row[n]))
      io.write(separator) if col != columns[-1]
    end
    io.write(finalizer)
    io.write("\n")
  end
  
  alias << print_row

  def resize_columns data, full_width: nil
    full_width ||= IO.console.winsize[1]
    full_width -= decorator.decor_width(:row, columns.size)

    widths = initial_column_widths(data, full_width)
    widths = shrink_columns_to_fit(widths, full_width)
    widths = size_any_size_columns(widths, full_width)
    widths = expand_columns_to_fit(widths, full_width)

    columns.zip(widths).each do |col, w|
      col.real_width = w
    end
  end

  def print_bar style = :bar
    decorator[style] => { leader:, filler:, separator:, finalizer: }
    io.write(leader)
    columns.each_with_index do |col, n|
      io.write(filler * col.real_width)
      io.write(separator) if col != columns[-1]
    end
    io.write(finalizer)
    io.write("\n")
  rescue NoMatchingPatternError
  end
  
  protected
  
  def print_headers
    decorator[:row] => { leader:, separator:, finalizer: }
    io.write(leader)
    columns.each_with_index do |col, n|
      io.write(col.align(col.title, align: :center))
      io.write(separator) if col != columns[-1]
    end
    io.write(finalizer)
    io.write("\n")
  end

  def initial_column_widths data, full_width
    columns.each_with_index.collect do |col, n|
      case col.strategy.to_s
      when 'fixed' then col.width
      when 'fitted' then [ col.width || 0,
                           data.collect { |row|
                             col.format(row[n], align: false)&.size || 0
                           }.max
                         ].max
      when 'percent' then full_width * [ 1.0, col.width ].min
      else nil
      end
    end
  end
  
  def shrink_columns_to_fit widths, full_width
    while widths.reject(&:nil?).sum >= full_width
      widths = columns.zip(widths).collect do |col, width|
        next width if width == nil || widths.reject(&:nil?).sum < full_width
        case col.strategy.to_s
        when 'fixed' then width
        when 'fitted' then [ col.width || 0, width - 1 ].max
        when 'percent' then width - 1
        else [ col.width || 0, width - 1 ].max
        end
      end
    end

    widths
  end

  def size_any_size_columns widths, full_width
    left_over = full_width - widths.reject(&:nil?).sum
    eq_width = left_over / [ 1, widths.count(&:nil?) ].max
    widths.each_with_index do |cw, n|
      widths[n] ||= eq_width
      widths[n] = [0, widths[n] ].max
    end
    widths
  end

  def expand_columns_to_fit widths, full_width
    last_sum = nil
    while (this_sum = widths.reject(&:nil?).sum) < full_width-2
      break if last_sum && last_sum == this_sum
      last_sum = this_sum
      
      widths = columns.zip(widths).collect do |col, width|
        next width if width == nil || widths.reject(&:nil?).sum >= full_width-2
        case col.strategy.to_s
        when 'fixed' then width
        when 'fitted' then [ col.width || 0, width + 1 ].max
        when 'percent' then width + 1
        else [ col.width || 0, width + 1 ].max
        end
      end
    end

    widths
  end

  def self.run(args = ARGV)
    require 'optparse'
    
    table_width = nil
    first_line_headers = false
    decorator = nil
    skip_lines = 0
    delimeter = nil
    
    args = OptionParser.new do |o|
      o.banner = <<-EOT
#{$0} [options] columns...

Print out a tabulated data set into columns. Data is read
from standard input.

EOT
      
      o.on('--width N', Integer) do |v|
        table_width = v
      end

      o.on('--skip N', Integer) do |v|
        skip_lines = v
      end

      o.on('--first-line-headers') do
        first_line_headers = true
      end

      o.on('--style STYLE') do |v|
        decorator = SG::TablePrinter::Decorator.new(v.underscore.to_sym)
      end
      
      o.on('--delimeter REGEXP') do |v|
        delimeter = Regexp.new(v)
      end
      
      o.separator <<-EOT

Columns are specified by: name:strategy:align:width:formatter

Only name is required. Strategy is one of fitted, fixed, percent,
or fill. Align can be left, center, or right. Width depends on
the strategy. Literally the width of fixed columns. Fitted uses
as a minimum. Percent uses it as a weight between 0.0 and 1.0.
EOT
    end.parse(args)

    first_line = nil
    tbl = SG::TablePrinter.new(decorator: decorator)
    if args.empty?
      if first_line_headers
        line = $stdin.readline.split(delimeter).collect(&:strip)
        line.each do |col|
          tbl.add_column(title: col)
        end
      else
        first_line = $stdin.readline.split(delimeter).collect(&:strip)
        first_line.each_with_index do |col, n|
          tbl.add_column(title: n.to_s)
        end
      end
    else
      args.each do |arg|
        name, strategy, align, width, formatter = arg.split(':').collect { |a| a.blank? ? nil : a }
        tbl.add_column(title: name,
                       strategy: strategy,
                       align: align&.to_sym,
                       width: width&.to_f,
                       formatter: formatter)
      end
    end

    data = $stdin.readlines
    if skip_lines > 0
      data = data.drop(skip_lines - (first_line ? 1 : 0))
      first_line = nil
    end

    data = data.collect { |r| r.split(delimeter).collect(&:strip) }
    if skip_lines <= 0 && args.empty? && first_line
      data = [ first_line ].each + data
    end
    #tbl.resize_columns(data.dup, full_width: table_width)
    tbl.print(data, width: table_width)
  end
end

if $0 == __FILE__
  SG::TablePrinter.run
end
