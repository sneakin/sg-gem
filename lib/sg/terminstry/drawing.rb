# coding: utf-8
require 'io/console'
require_relative 'constants'
require_relative 'util'
require 'sg/ext'

using SG::Ext

module SG::Terminstry::Drawing
  # Returns a string that prints lines into an outlined box.
  # The box looks like:
  # <pre>
  # ▁▁▁▁▁▁▁▁▁
  # ▌ Title ▐▁▁▁▁▁
  # ▌ Content    ▐
  # ▌ Content    ▐
  # ▌ Content    ▐
  # ▔▔▔▔▔▔▔▔▔▔▔▔▔▔
  # </pre>
  def self.tabbox(title, content,
                  tty: SG::Terminstry::Terminals.global,
                  size: [ SG::Terminstry.tty_size[0], 0 ],
                  bg: nil, fg: nil,
                  borderbg: nil, borderfg: fg,
                  titlefg: fg)
    normal = tty.normal
    bold = tty.bold
    border = normal + tty.fgbg(borderfg, borderbg)
    color = normal + tty.fgbg(fg, bg)
    title_color = normal + tty.fgbg(titlefg, bg)
    bordcol = normal + tty.fgbg(borderfg, bg)
    title = title.truncate(size[0] - 4)
    s = []
    s << "%s%s\n" % [ border, '▁' * (title.screen_size + 4) ]
    s << "%s▌%s %s%s %s%s▐%s%s%s\n" % [ bordcol, title_color, bold, title, normal, bordcol, border, '▁' * [ 0, (size[0] - title.screen_size - 4) ].max, border ]
    parts = []
    content.each_line do |l|
      l.each_visual_slice(size[0] - 4) do |p|
        parts << p
      end
    end
    [ 0, (size[1] - parts.size) ].max.times { |_n| parts << '' }
    s += parts.collect do |l|
      l = l.rstrip
      "%s▌%s %s%s%s▐%s\n" % [ bordcol, color, l, ' ' * [ (size[0] - 3 - l.screen_size), 0 ].max, bordcol, border ]
    end
    s << '%s%s%s' % [ border, '▔' * size[0], border ]
    s.join
  end
end
