# frozen_string_literal: true

require 'thor'
require 'json'
require 'time'
require 'jules-ruby/errors'

module JulesRuby
  module Commands
    # Base class for CLI subcommands with shared helper methods
    class Base < Thor
      # Helper to define the common format option
      def self.format_option
        method_option :format, type: :string, default: 'table', enum: %w[table json], desc: 'Output format'
      end

      no_commands do
        def client
          @client ||= JulesRuby::Client.new
        end

        def error_exit(error)
          if options[:format] == 'json'
            puts JSON.generate({ error: error.message })
          else
            # UX Improvement: Colored error label and helpful hints using Thor's built-in color
            # Use shell.set_color to ensure we are using the shell's capabilities correctly
            error_label = shell.set_color('Error:', :red)
            warn "#{error_label} #{error.message}"

            if error.is_a?(JulesRuby::ConfigurationError)
              warn "\n  💡 Tip: Set JULES_API_KEY environment variable or check your config."
              warn "     See https://developers.google.com/jules/api for more info."
            end
          end
          exit 1
        end

        def truncate(str, length)
          return '' unless str

          str.length > length ? "#{str[0...(length - 3)]}..." : str
        end
      end
    end
  end
end
