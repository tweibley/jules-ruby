# frozen_string_literal: true

require 'thor'
require 'json'
require 'time'
require 'pastel'
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
            pastel = Pastel.new
            warn "#{pastel.red('Error:')} #{error.message}"

            case error
            when JulesRuby::ConfigurationError
              warn pastel.dim('Hint: Check your environment variables (JULES_API_KEY).')
            when JulesRuby::AuthenticationError
              warn pastel.dim('Hint: Verify your API key is correct.')
            when JulesRuby::NotFoundError
              warn pastel.dim('Hint: The requested resource could not be found.')
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
