# frozen_string_literal: true

require 'thor'
require_relative 'cli/interactive'
require_relative 'cli/prompts'

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
    subcommand 'sources', Class.new(Thor) {
      desc 'list', 'List all connected repositories'
      long_desc <<~LONGDESC
        List all GitHub repositories connected to your Jules account.

        Examples:
          $ jules-ruby sources list
          $ jules-ruby sources list --format=json
      LONGDESC
      method_option :format, type: :string, default: 'table', enum: %w[table json], desc: 'Output format'
      def list
        sources = client.sources.all
        if options[:format] == 'json'
          puts JSON.pretty_generate(sources.map(&:to_h))
        else
          print_sources_table(sources)
        end
      rescue JulesRuby::Error => e
        error_exit(e)
      end

      desc 'show NAME', 'Show details for a source'
      long_desc <<~LONGDESC
        Show details for a specific source.

        Example:
          $ jules-ruby sources show sources/github/owner/repo
      LONGDESC
      method_option :format, type: :string, default: 'table', enum: %w[table json], desc: 'Output format'
      def show(name)
        source = client.sources.find(name)
        if options[:format] == 'json'
          puts JSON.pretty_generate(source.to_h)
        else
          print_source_details(source)
        end
      rescue JulesRuby::Error => e
        error_exit(e)
      end

      private

      def client
        @client ||= JulesRuby::Client.new
      end

      def print_sources_table(sources)
        if sources.empty?
          puts 'No sources found.'
          return
        end
        puts format('%-50s %-20s', 'NAME', 'REPOSITORY')
        puts '-' * 72
        sources.each do |s|
          puts format('%-50s %-20s', s.name, s.github_repo&.full_name || 'N/A')
        end
      end

      def print_source_details(source)
        puts "Name:       #{source.name}"
        puts "ID:         #{source.id}"
        return unless source.github_repo

        puts "Repository: #{source.github_repo.full_name}"
        puts "URL:        #{source.github_repo.url}" if source.github_repo.respond_to?(:url)
      end

      def error_exit(error)
        if options[:format] == 'json'
          puts JSON.generate({ error: error.message })
        else
          warn "Error: #{error.message}"
        end
        exit 1
      end
    }

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
    subcommand 'sessions', Class.new(Thor) {
      desc 'list', 'List all sessions'
      method_option :format, type: :string, default: 'table', enum: %w[table json], desc: 'Output format'
      def list
        sessions = client.sessions.all
        if options[:format] == 'json'
          puts JSON.pretty_generate(sessions.map(&:to_h))
        else
          print_sessions_table(sessions)
        end
      rescue JulesRuby::Error => e
        error_exit(e)
      end

      desc 'show ID', 'Show details for a session'
      method_option :format, type: :string, default: 'table', enum: %w[table json], desc: 'Output format'
      def show(id)
        session = client.sessions.find(id)
        if options[:format] == 'json'
          puts JSON.pretty_generate(session.to_h)
        else
          print_session_details(session)
        end
      rescue JulesRuby::Error => e
        error_exit(e)
      end

      desc 'create', 'Create a new session'
      long_desc <<~LONGDESC
        Create a new Jules coding session.

        You must provide a prompt either inline with --prompt or from a file with --prompt-file.
        If both are provided, --prompt-file takes precedence.

        Examples:

          # Create with inline prompt
          $ jules-ruby sessions create --source=sources/github/owner/repo --prompt="Fix the login bug"

          # Create with prompt from file
          $ jules-ruby sessions create --source=sources/github/owner/repo --prompt-file=./task-instructions.md

          # Create with custom branch and auto-PR
          $ jules-ruby sessions create --source=sources/github/owner/repo --branch=develop --prompt="Add tests" --auto-pr
      LONGDESC
      option :source, required: true, desc: 'Source name (e.g., sources/github/owner/repo)'
      option :branch, default: 'main', desc: 'Starting branch'
      option :prompt, desc: 'Task prompt (inline text)'
      option :prompt_file, desc: 'Path to file containing task prompt'
      option :title, desc: 'Session title'
      option :auto_pr, type: :boolean, default: false, desc: 'Auto-create PR when done'
      def create
        prompt_text = resolve_prompt
        raise Thor::Error, 'You must provide --prompt or --prompt-file' if prompt_text.nil? || prompt_text.strip.empty?

        source_context = {
          'source' => options[:source],
          'githubRepoContext' => { 'startingBranch' => options[:branch] }
        }

        params = {
          prompt: prompt_text,
          source_context: source_context
        }
        params[:title] = options[:title] if options[:title]
        params[:automation_mode] = 'AUTO_CREATE_PR' if options[:auto_pr]

        session = client.sessions.create(**params)
        puts "Session created: #{session.name}"
        puts "URL: #{session.url}"
        puts "State: #{session.state}"
      rescue JulesRuby::Error => e
        error_exit(e)
      end

      desc 'approve ID', 'Approve the plan for a session'
      long_desc <<~LONGDESC
        Approve the generated plan for a session.

        Example:
          $ jules-ruby sessions approve SESSION_ID
      LONGDESC
      def approve(id)
        session = client.sessions.approve_plan(id)
        puts "Plan approved for session: #{session.name}"
        puts "State: #{session.state}"
      rescue JulesRuby::Error => e
        error_exit(e)
      end

      desc 'message ID', 'Send a message to a session'
      long_desc <<~LONGDESC
        Send a message to an existing session.

        Examples:
          $ jules-ruby sessions message SESSION_ID --prompt="Please also add unit tests"
      LONGDESC
      option :prompt, required: true, desc: 'Message to send'
      def message(id)
        session = client.sessions.send_message(id, prompt: options[:prompt])
        puts "Message sent to session: #{session.name}"
        puts "State: #{session.state}"
      rescue JulesRuby::Error => e
        error_exit(e)
      end

      desc 'delete ID', 'Delete a session'
      def delete(id)
        client.sessions.destroy(id)
        puts "Session deleted: #{id}"
      rescue JulesRuby::Error => e
        error_exit(e)
      end

      private

      def resolve_prompt
        if options[:prompt_file]
          file_path = File.expand_path(options[:prompt_file])
          raise Thor::Error, "Prompt file not found: #{file_path}" unless File.exist?(file_path)

          File.read(file_path)
        else
          options[:prompt]
        end
      end

      def client
        @client ||= JulesRuby::Client.new
      end

      def print_sessions_table(sessions)
        if sessions.empty?
          puts 'No sessions found.'
          return
        end
        puts format('%-20s %-30s %-20s %-15s', 'ID', 'TITLE', 'STATE', 'UPDATED')
        puts '-' * 90
        sessions.each do |s|
          title = truncate(s.title || s.prompt, 28)
          updated = s.update_time ? Time.parse(s.update_time).strftime('%Y-%m-%d %H:%M') : 'N/A'
          puts format('%-20s %-30s %-20s %-15s', s.id, title, s.state, updated)
        end
      end

      def print_session_details(session)
        puts "Name:    #{session.name}"
        puts "ID:      #{session.id}"
        puts "Title:   #{session.title}" if session.title
        puts "Prompt:  #{session.prompt}"
        puts "State:   #{session.state}"
        puts "URL:     #{session.url}" if session.url
        puts "Created: #{session.create_time}"
        puts "Updated: #{session.update_time}"
        return unless session.outputs&.any?

        puts "\nOutputs:"
        session.outputs.each do |output|
          if output.respond_to?(:url)
            puts "  - PR: #{output.url}"
          else
            puts "  - #{output}"
          end
        end
      end

      def truncate(str, length)
        return '' unless str

        str.length > length ? "#{str[0...(length - 3)]}..." : str
      end

      def error_exit(error)
        if options[:format] == 'json'
          puts JSON.generate({ error: error.message })
        else
          warn "Error: #{error.message}"
        end
        exit 1
      end
    }

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
    subcommand 'activities', Class.new(Thor) {
      desc 'list SESSION_ID', 'List activities for a session'
      long_desc <<~LONGDESC
        List all activities for a session (messages, plans, progress updates).

        Example:
          $ jules-ruby activities list SESSION_ID
      LONGDESC
      method_option :format, type: :string, default: 'table', enum: %w[table json], desc: 'Output format'
      def list(session_id)
        activities = client.activities.all(session_id)
        if options[:format] == 'json'
          puts JSON.pretty_generate(activities.map(&:to_h))
        else
          print_activities_table(activities)
        end
      rescue JulesRuby::Error => e
        error_exit(e)
      end

      desc 'show NAME', 'Show details for an activity'
      long_desc <<~LONGDESC
        Show details for a specific activity.

        Example:
          $ jules-ruby activities show sessions/SESSION_ID/activities/ACTIVITY_ID
      LONGDESC
      method_option :format, type: :string, default: 'table', enum: %w[table json], desc: 'Output format'
      def show(name)
        activity = client.activities.find(name)
        if options[:format] == 'json'
          puts JSON.pretty_generate(activity.to_h)
        else
          print_activity_details(activity)
        end
      rescue JulesRuby::Error => e
        error_exit(e)
      end

      private

      def client
        @client ||= JulesRuby::Client.new
      end

      def print_activities_table(activities)
        if activities.empty?
          puts 'No activities found.'
          return
        end
        puts format('%-20s %-20s %-10s %-40s', 'ID', 'TYPE', 'FROM', 'DESCRIPTION')
        puts '-' * 95
        activities.each do |a|
          desc = truncate(activity_summary(a), 38)
          puts format('%-20s %-20s %-10s %-40s', a.id, a.type, a.originator || 'N/A', desc)
        end
      end

      def print_activity_details(activity)
        puts "Name:        #{activity.name}"
        puts "ID:          #{activity.id}"
        puts "Type:        #{activity.type}"
        puts "Originator:  #{activity.originator}"
        puts "Created:     #{activity.create_time}"
        puts "Description: #{activity.description}" if activity.description

        case activity.type
        when :agent_messaged, :user_messaged
          puts "\nMessage:"
          puts "  #{activity.message}"
        when :plan_generated
          if activity.plan
            puts "\nPlan:"
            activity.plan.steps&.each_with_index do |step, i|
              puts "  #{i + 1}. #{step.title}"
            end
          end
        when :progress_updated
          puts "\nProgress: #{activity.progress_title}"
          puts "Details:  #{activity.progress_description}" if activity.progress_description
        when :session_failed
          puts "\nFailure Reason: #{activity.failure_reason}"
        end

        return unless activity.artifacts&.any?

        puts "\nArtifacts:"
        activity.artifacts.each do |artifact|
          puts "  - Type: #{artifact.type}"
        end
      end

      def activity_summary(activity)
        case activity.type
        when :agent_messaged, :user_messaged
          activity.message || ''
        when :plan_generated
          "Plan with #{activity.plan&.steps&.length || 0} steps"
        when :progress_updated
          activity.progress_title || ''
        when :session_completed
          'Session completed'
        when :session_failed
          activity.failure_reason || 'Session failed'
        else
          activity.description || ''
        end
      end

      def truncate(str, length)
        return '' unless str

        str.length > length ? "#{str[0...(length - 3)]}..." : str
      end

      def error_exit(error)
        if options[:format] == 'json'
          puts JSON.generate({ error: error.message })
        else
          warn "Error: #{error.message}"
        end
        exit 1
      end
    }

    desc 'version', 'Show jules-ruby version'
    def version
      puts "jules-ruby #{JulesRuby::VERSION}"
    end

    map %w[-v --version] => :version
  end
end
