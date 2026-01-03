# frozen_string_literal: true

require 'thor'
require 'json'
require 'time'

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
            warn "Error: #{error.message}"
            if error.is_a?(JulesRuby::ConfigurationError)
              warn "\nTo fix this:"
              warn "  export JULES_API_KEY='your_api_key_here'"
              warn "\nGet your API key at: https://developers.google.com/jules/api"
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
