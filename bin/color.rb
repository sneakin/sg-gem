#!/usr/bin/env ruby

$: << File.join(File.dirname(File.dirname(__FILE__)), 'lib')

# Shell script helpers for color usage, previewing, and fun.
if $0 == __FILE__
  require 'optparse'
  require 'sg/terminstry/terminals'

  Terminals = SG::Terminstry::Terminals
  Color = SG::Color

  # Presently a test for Yard handlers  
  args = OptionParser.new do |o|
    o.banner = "Color helpers and demos."
    o.separator "Usage: #{$0} command args..."

    o.on('-v', '--verbose') do
      puts($0)
      exit(-1)
    end

    o.on('-c', '--color VALUE', 'Color value to use.') do |v|
      puts(v.inspect)
    end
  end.parse!(ARGV)
  
  vt100 = Terminals.make_tty
  case ARGV.shift
  when 'normal' then # @cmd Print the code to reset the TTY.
    $stdout.write(vt100.normal)
  when 'rgb' then # @cmd Print the escape code for an RGB color.
    fg = Color::RGB.new(*ARGV[0,3].collect { |a| a.to_f })
    if ARGV[3,3].size == 3
      bg = Color::RGB.new(*ARGV[3,3].collect { |a| a.to_f })
      $stdout.write(vt100.fgbg(fg, bg))
    else
      $stdout.write(vt100.fg(fg))
    end
  when 'hsl' then # @cmd Print the escape code for an HSL color.
    fg = Color::HSL.new(*ARGV[0,3].collect { |a| a.to_f })
    bg = Color::HSL.new(*ARGV[3,3].collect { |a| a.to_f })
    $stdout.write(vt100.fgbg(fg, bg))
  when 'gray' then # @cmd Print the escape code for a gray.
    gray = Color::Gray.new(ARGV[0].to_f)
    puts("%s%f%s  %s%f%s" %
         [ vt100.fgbg(gray.invert, gray), ARGV[0].to_f, vt100.normal,
           vt100.fgbg(gray, Color::RGB.new(0)), ARGV[0].to_f, vt100.normal])
  when 'rgb-hsl' then # @cmd Convert RGB to HSL for side by side comparison.
    rgb = Color::RGB.new(*ARGV[0,3].collect { |a| a.to_f })
    hsl = rgb.to(Color::HSL)
    puts("%s%.2f %.2f %.2f%s  %s%.2f %.2f %.2f%s" %
         [ vt100.fgbg(hsl.invert, hsl), *hsl, vt100.normal,
           vt100.fgbg(hsl, Color::RGB.new(0)), *hsl, vt100.normal])
  when 'hsl-rgb' then # @cmd Convert HSL to RGB for side by side comparison.
    hsl = Color::HSL.new(*ARGV[0,3].collect(&:to_f))
    rgb = hsl.to(Color::RGB)
    puts("%s%3i %3i %3i%s  %s%3i %3i %3i%s" %
         [ vt100.fgbg(rgb.invert, rgb), *rgb, vt100.normal,
           vt100.fgbg(rgb, Color::RGB.new(0)), *rgb, vt100.normal ])
  when /^([-+*\/.])$/ then # @cmd Print a list of named colors.
    op = $1.to_sym
    colors = ARGV.collect { |a| Color.from_string(a) }
    r = colors[1..-1].reduce(colors[0]) { |a, c| a.send(op, c) }.clamp
    s = colors.collect { |c| "%s%s%s" % [ vt100.fg(c), c, vt100.normal ] }.
          join(" #{op} ")
    s += " = %s%s%s" % [ vt100.fg(r), r, vt100.normal ]
    puts(s)
  when 'swatch' then # @cmd Print the entire HSL colorspace.
    s = (ARGV[2] || 1).to_f
    lines = (ARGV[1] || (ENV.fetch('LINES', 24).to_i - 1))
    cols = (ARGV[0] || (ENV.fetch('COLUMNS', 40).to_i - 4))
    Range.new(0.0, 1.0).step(1.0 / lines.to_f).each do |l|
      gray = Color::Gray.new(l)
      $stdout.write("%s\u2588\u2588%s " % [ vt100.fgbg(gray, gray), vt100.normal ])
      Range.new(0, 360).step(360.0 / cols.to_f).each do |h|
        color = Color::HSL.new(h, s, l)
        $stdout.write("%s\u2588" % [ vt100.fgbg(color, color) ])
      end
      $stdout.puts(vt100.normal)
    end
  when 'rgb-grad' then # @cmd Print a gradient that uses the whole RGB colorspace.
    rows = (ARGV[1] || ENV.fetch('LINES', 20)).to_i - 1
    cols = (ARGV[0] || ENV.fetch('COLUMNS', 20)).to_i - 1
    style = ARGV[2].to_i
    Range.new(0, 1.0).step(1.0 / rows.to_f) do |row|
      Range.new(0, 1.0).step(1.0 / cols.to_f) do |col|
        bcol = col * 255
        brow = row * 255
        color = if style == 1
                  Color::RGB.new(brow, bcol, 255 - brow)
                else
                  Color::RGB.new([ 0, brow - bcol ].max,
                                 [ 0, bcol - brow ].max,
                                 row * col * 255)
                end
        $stdout.write("%s\u2588" % [ vt100.fgbg(color, color) ])
      end
      $stdout.puts(vt100.normal)
    end
  when /-*help/ then # @cmd Print this list.
    require 'sg/selfhelp'
    SG::SelfHelp.print
  else raise ArgumentError.new("Unknown mode.")
  end
end
