#!/usr/bin/env -S ruby -W:no-experimental
# -*- coding: utf-8 -*-
require 'bundler/setup'
require 'sg/terminstry/util'
require 'sg/ext'
using SG::Ext

# todo multiline cells

# A plain text table printer for Enumerables.
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

    def format value, align: true, stripped: false
      v = formatter.call(value)
      v = align(v, stripped: stripped) if align
      v
    end

    def align v, align: alignment, width: real_width, stripped: false
      return v if width == nil
      return v.strip if stripped == :fully
      s = (v || '').truncate(width)
      if s.screen_size < width
        case align
        when :center then s = s.center_visually(width).skip_unless(stripped).rstrip
        when :right then s = s.rjust_visually(width)
        else s = stripped ? s : s.ljust_visually(width)
        end
      end
      s
    end
  end

  class Decorator
    None = {
      flags: [ :stripped ],
      row: { leader: '', separator: '  ', finalizer: '' },
      #bar: { filler: ' ', leader: '', separator: ' ', finalizer: '' },
      #top_bar: { filler: ' ', leader: '', separator: ' ', finalizer: '' },
      #bottom_bar: { filler: ' ', leader: '', separator: ' ', finalizer: '' }
    }
    Ascii = {
      top_bar: { filler: '-', leader: '+-', separator: '-+-', finalizer: '-+' },
      header_bar: { filler: '-', leader: '+-', separator: '-+-', finalizer: '-+' },
      row: { leader: '| ', separator: ' | ', finalizer: ' |' },
      bar: { filler: '-', leader: '+-', separator: '-+-', finalizer: '-+' },
      bottom_bar: { filler: '-', leader: '+-', separator: '-+-', finalizer: '-+' }
    }
    Org = {
      header_bar: { filler: '-', leader: '|-', separator: '-+-', finalizer: '-|' },
      row: { leader: '| ', separator: ' | ', finalizer: ' |' },
      bar: { filler: '-', leader: '|-', separator: '-+-', finalizer: '-|' },
    }
    Box = {
      top_bar: { filler: '─', leader: '┌─', separator: '─┬─', finalizer: '─┐' },
      header_row: { leader: '│ ', separator: ' │ ', finalizer: ' │' },
      header_bar: { filler: '─', leader: '├─', separator: '─┼─', finalizer: '─┤' },
      row: { leader: '│ ', separator: ' │ ', finalizer: ' │' },
      bar: { filler: '─', leader: '├─', separator: '─┼─', finalizer: '─┤' },
      bottom_bar: { filler: '─', leader: '└─', separator: '─┴─', finalizer: '─┘' }
    }
    VT100 = {
      top_bar: { filler: "q", leader: "\e(0lq", separator: "qwq", finalizer: "qk\e(B" },
      header_row: { leader: "\e(0x\e(B ", separator: " \e(0x\e(B ", finalizer: " \e(0x\e(B" },
      header_bar: { filler: "q", leader: "\e(0tq", separator: "qnq", finalizer: "qu\e(B" },
      row: { leader: "\e(0x\e(B ", separator: " \e(0x\e(B ", finalizer: " \e(0x\e(B" },
      bar: { filler: "q", leader: "\e(0tq", separator: "qnq", finalizer: "qu\e(B" },
      bottom_bar: { filler: "q", leader: "\e(0mq", separator: "qvq", finalizer: "qj\e(B" }
    }
    HTML = {
      flags: [ :stripped, :noalign ],
      top_bar: { filler: '', leader: '<table>', separator: '', finalizer: '' },
      header_row: { leader: '<thead><tr><th>', separator: '</th><th>', finalizer: '</th></tr></thead>' },
      row: { leader: '<tr><td>', separator: '</td><td>', finalizer: '</td></tr>' },
      bottom_bar: { filler: '', leader: '', separator: '', finalizer: '</table>' }
    }

    Styles = {
      none: None,
      ascii: Ascii,
      org: Org,
      box: Box,
      vt100: VT100,
      html: HTML
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
      leader.screen_size + separator.screen_size * columns + finalizer.screen_size
    end

    def has_flag? name
      decor[:flags]&.include?(name)
    end
  end

  attr_reader :columns, :io, :decorator
  
  def initialize io: $stdout, decorator: nil, style: nil
    @columns = []
    @io = io
    @decorator = decorator || Decorator.new(style)
  end

  def add_column **opts
    @columns << Column.new(**opts)
    self
  end

  def print data, width: true, resize: true
    data = data.each unless Enumerator === data
    
    if columns.empty?
      line = data.first
      (line.size || 1).times { |n| add_column }
      if Enumerator::Lazy === data
        data = [ line ].each + data
      end
    end
    
    resize_columns(data, full_width: width) if resize
    print_bar(:top_bar)
    print_headers unless columns.all? { |c| c.title.blank? }
    data.each do |row|
      if row.blank? || row.all?(&:blank?)
        print_bar
      else
        print_row(row)
      end
    end
    print_bar(:bottom_bar)
  end

  def print_row row
    decorator[:row] => { leader:, separator:, finalizer: }
    io.write(leader)
    columns.each_with_index do |col, n|
      is_last_col = col == columns[-1]
      if is_last_col
        io.write(col.format(row[n],
                            stripped: decorator.has_flag?(:noalign) ? :fully :
                            (finalizer.blank? || decorator.has_flag?(:stripped))))
      else
        io.write(col.format(row[n], stripped: decorator.has_flag?(:noalign) ? :fully : false))
        io.write(separator)
      end
    end
    io.write(finalizer)
    io.write("\n")
    io.flush
    self
  end
  
  alias << print_row

  # todo tables with no width: everything is fitted
  def resize_columns data, full_width: true
    full_width = nil if decorator.has_flag?(:noalign)
    
    if full_width == true
      full_width = SG::Terminstry.tty_size&.first
    end
    
    if full_width
      full_width -= decorator.decor_width(:row, columns.size)
    end

    if full_width
      widths = sized_initial_column_widths(data, full_width)
      widths = shrink_columns_to_fit(widths, full_width)
      widths = size_any_size_columns(widths, full_width)
      widths = expand_columns_to_fit(widths, full_width)
    else
      widths = fitted_initial_column_widths(data)
    end

    columns.zip(widths).each do |col, w|
      col.real_width = w
    end

    self
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
    self
  rescue NoMatchingPatternError
    io.write("\n") if style == :bar
  ensure
  end
  
  def print_headers
    (decorator[:header_row] || decorator[:row]) => { leader:, separator:, finalizer: }
    io.write(leader)
    columns.each_with_index do |col, n|
      is_last_col = col == columns[-1]
      if is_last_col
        io.write(col.align(col.title, align: :center, stripped: decorator.has_flag?(:noalign) ? :fully : (finalizer.blank? || decorator.has_flag?(:stripped))))
      else
        io.write(col.align(col.title, align: :center, stripped: decorator.has_flag?(:noalign) ? :fully : false))
        io.write(separator)
      end
    end
    io.write(finalizer)
    io.write("\n")
    print_bar(:header_bar)
    self
  end

  protected
  
  def sized_initial_column_widths data, full_width
    columns.each_with_index.collect do |col, n|
      case col.strategy.to_s
      when 'fixed' then col.width
      when 'fitted' then fitted_column_width(col, n, data)
      when 'percent' then full_width * [ 1.0, col.width ].min
      else nil
      end
    end
  end
  
  def fitted_initial_column_widths data
    columns.each_with_index.collect do |col, n|
      case col.strategy.to_s
      when 'fixed' then col.width
      else fitted_column_width(col, n, data)
      end
    end
  end
  
  def fitted_column_width col, col_num, data
    [ col.width || 0,
      data.collect { |row|
        col.format(row[col_num], align: false)&.screen_size || 0
      }.max || 0
    ].max
  end
  
  def shrink_columns_to_fit widths, full_width
    last_sum = nil
    while (this_sum = widths.reject(&:nil?).sum) >= full_width
      break if last_sum && last_sum == this_sum
      last_sum = this_sum
      
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
    
    table_width = true
    first_line_headers = false
    decorator = nil
    skip_lines = 0
    delimeter = nil
    follow_mode = false
    
    args = OptionParser.new do |o|
      o.banner = <<-EOT
#{$0} [options] columns...

Print out a tabulated data set into columns. Data is read
from standard input.

EOT
      
      o.on('--width N', Integer) do |v|
        table_width = v <= 0 ? nil : v
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
        delimeter = v =~ /\A\/(.*)\/\Z/ ? Regexp.new($1) : v
      end

      o.on('-f', '--[no-]follow') do |v|
        follow_mode = v
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
        line = $stdin.readline.split(delimeter).collect(&:strip).each do |col|
          tbl.add_column(title: col)
        end
      else
        first_line = $stdin.readline.split(delimeter).collect(&:strip).each do |col|
          tbl.add_column()
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

    data = $stdin.each_line.skip_unless(follow_mode).lazy
    if skip_lines > 0
      data = data.drop(skip_lines - (first_line ? 1 : 0))
      first_line = nil
    end

    data = data.collect { |r| r.split(delimeter).collect(&:strip) }
    if skip_lines <= 0 && args.empty? && first_line
      data = [ first_line ].each + data
    end
    
    tbl.print(data, width: table_width)
  end
end

if $0 == __FILE__
  SG::TablePrinter.run
end
