# frozen_string_literal: true

require 'thor'
require_relative 'cli/interactive'
require_relative 'cli/prompts'
require_relative 'cli/sources'
require_relative 'cli/sessions'
require_relative 'cli/activities'

module JulesRuby
  # Command-line interface for jules-ruby
  class CLI < Thor
    package_name 'jules-ruby'

    def self.exit_on_failure?
      true
    end

    def self.help(shell, subcommand = false)
      Prompts.print_banner

      shell.say <<~BANNER
        QUICK START EXAMPLES:

          # Start interactive mode (default)
          $ jules-ruby

          # List your connected repositories
          $ jules-ruby sources list

          # Create a new coding session
          $ jules-ruby sessions create --source=sources/github/owner/repo --prompt="Fix the login bug"

          # Create a session with prompt from file
          $ jules-ruby sessions create --source=sources/github/owner/repo --prompt-file=./task.md

          # List all sessions
          $ jules-ruby sessions list

          # View session activities
          $ jules-ruby activities list SESSION_ID

          # Approve a session's plan
          $ jules-ruby sessions approve SESSION_ID

        CONFIGURATION:

          Set your API key via environment variable:
          $ export JULES_API_KEY=your_api_key

      BANNER
      super
    end

    desc 'interactive', 'Start interactive mode'
    def interactive
      JulesRuby::Interactive.new.start
    rescue JulesRuby::ConfigurationError => e
      Prompts.print_config_error(e)
      exit 1
    end

    map %w[-i] => :interactive
    default_command :interactive

    desc 'sources SUBCOMMAND', 'Manage sources (connected repositories)'
    long_desc <<~LONGDESC
      Manage connected GitHub repositories (sources).

      Examples:

        # List all connected repositories
        $ jules-ruby sources list

        # Show details for a specific source
        $ jules-ruby sources show sources/github/owner/repo

        # Output as JSON
        $ jules-ruby sources list --format=json
    LONGDESC
    subcommand 'sources', JulesRuby::Commands::Sources

    desc 'sessions SUBCOMMAND', 'Manage coding sessions'
    long_desc <<~LONGDESC
      Manage Jules coding sessions.

      Examples:

        # List all sessions
        $ jules-ruby sessions list

        # Show session details
        $ jules-ruby sessions show SESSION_ID

        # Create a session with inline prompt
        $ jules-ruby sessions create --source=sources/github/owner/repo --prompt="Fix the login bug"

        # Create a session with prompt from file
        $ jules-ruby sessions create --source=sources/github/owner/repo --prompt-file=./task.md

        # Create a session with auto-PR
        $ jules-ruby sessions create --source=sources/github/owner/repo --prompt="Add tests" --auto-pr
    LONGDESC
    subcommand 'sessions', JulesRuby::Commands::Sessions

    desc 'activities SUBCOMMAND', 'View session activities'
    long_desc <<~LONGDESC
      View activities (messages, plans, progress) for Jules sessions.

      Examples:

        # List all activities for a session
        $ jules-ruby activities list SESSION_ID

        # Show details for a specific activity
        $ jules-ruby activities show sessions/SESSION_ID/activities/ACTIVITY_ID

        # Output as JSON
        $ jules-ruby activities list SESSION_ID --format=json
    LONGDESC
    subcommand 'activities', JulesRuby::Commands::Activities

    desc 'version', 'Show jules-ruby version'
    def version
      puts "jules-ruby #{JulesRuby::VERSION}"
    end

    map %w[-v --version] => :version
  end
end
