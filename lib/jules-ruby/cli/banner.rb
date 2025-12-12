# frozen_string_literal: true

module JulesRuby
  # ASCII art banner for the CLI
  module Banner
    # Octopus ASCII art - matching Jules logo
    OCTOPUS = [
      '            ████████████████            ',
      '        ████████████████████████        ',
      '      ████████████████████████████      ',
      '     ██████████████████████████████     ',
      '    ████████████████████████████████    ',
      '    ████████████████████████████████    ',
      '    ████████████████████████████████    ',
      '    ████████  ████████████  ████████    ',
      '    ████████  ████████████  ████████    ',
      '    ████████████████████████████████    ',
      '     ██████████████████████████████     ',
      '      ████████████████████████████      ',
      '       ██    ██████████████    ██       ',
      '       ██    ████      ████    ██       ',
      '       ██    ████      ████    ██       ',
      '       ██    ████      ████    ██       ',
      ' ██    ██    ████      ████    ██    ██ ',
      '  ██   ██     ██        ██     ██   ██  ',
      '   ██████                      ██████   '
    ].freeze

    # Jules text banner
    JULES_TEXT = [
      '                                            ',
      '                                            ',
      '       ██╗██╗   ██╗██╗     ███████╗███████╗ ',
      '       ██║██║   ██║██║     ██╔════╝██╔════╝ ',
      '       ██║██║   ██║██║     █████╗  ███████╗ ',
      '  ██   ██║██║   ██║██║     ██╔══╝  ╚════██║ ',
      '  ╚█████╔╝╚██████╔╝███████╗███████╗███████║ ',
      '   ╚════╝  ╚═════╝ ╚══════╝╚══════╝╚══════╝ ',
      '                                            ',
      '       ██████╗ ██╗   ██╗██████╗ ██╗   ██    ',
      '       ██╔══██╗██║   ██║██╔══██╗╚██╗ ██╔╝   ',
      '       ██████╔╝██║   ██║██████╔╝ ╚████╔╝    ',
      '       ██╔══██╗██║   ██║██╔══██╗  ╚██╔╝     ',
      '       ██║  ██║╚██████╔╝██████╔╝   ██║      ',
      '       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝    ╚═╝      ',
      '                                            ',
      '                                            '
    ].freeze

    class << self
      def hsl_to_rgb(h, s, l)
        s /= 100.0
        l /= 100.0

        c = (1 - ((2 * l) - 1).abs) * s
        x = c * (1 - (((h / 60.0) % 2) - 1).abs)
        m = l - (c / 2)

        r, g, b = case h
                  when 0...60 then [c, x, 0]
                  when 60...120 then [x, c, 0]
                  when 120...180 then [0, c, x]
                  when 180...240 then [0, x, c]
                  when 240...300 then [x, 0, c]
                  else [c, 0, x]
                  end

        [((r + m) * 255).round, ((g + m) * 255).round, ((b + m) * 255).round]
      end

      def print_banner
        num_lines = [OCTOPUS.length, JULES_TEXT.length].max
        octopus_width = OCTOPUS.map(&:length).max
        jules_width = JULES_TEXT.first&.length || 0

        num_lines.times do |row|
          octopus_line = OCTOPUS[row] || ''
          jules_line = JULES_TEXT[row] || ''

          # Pad octopus line to consistent width
          octopus_line = octopus_line.ljust(octopus_width)

          # Print octopus with purple gradient
          octopus_progress = row.to_f / num_lines
          oct_h = 255 + (10 * octopus_progress)
          oct_s = 80 - (5 * octopus_progress)
          oct_l = 65 - (15 * octopus_progress)
          oct_r, oct_g, oct_b = hsl_to_rgb(oct_h, oct_s, oct_l)

          octopus_line.each_char do |char|
            print "\e[38;2;#{oct_r};#{oct_g};#{oct_b}m#{char}\e[0m"
          end

          # Print jules text with red-to-purple horizontal gradient
          jules_line.each_char.with_index do |char, col|
            progress = col.to_f / jules_width

            # Red (hsl 348) to Purple (hsl 280)
            h = 348 + ((280 - 348) * progress)
            s = 83 + ((70 - 83) * progress)
            l = 47 + ((45 - 47) * progress)

            r, g, b = hsl_to_rgb(h, s, l)
            print "\e[38;2;#{r};#{g};#{b}m#{char}\e[0m"
          end

          puts
        end
        puts
      end
    end
  end
end
