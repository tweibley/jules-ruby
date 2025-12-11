# frozen_string_literal: true

require 'thor'
require_relative 'cli/interactive'

module JulesRuby
  # Command-line interface for jules-ruby
  class CLI < Thor
    class_option :format, type: :string, default: 'table', enum: %w[table json], desc: 'Output format'

    def self.exit_on_failure?
      true
    end

    desc 'interactive', 'Start interactive mode'
    def interactive
      JulesRuby::Interactive.new.start
    end

    map %w[-i] => :interactive
    default_command :interactive

    desc 'sources SUBCOMMAND', 'Manage sources (connected repositories)'
    subcommand 'sources', Class.new(Thor) {
      class_option :format, type: :string, default: 'table', enum: %w[table json], desc: 'Output format'

      desc 'list', 'List all connected repositories'
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
        warn "Error: #{error.message}"
        exit 1
      end
    }

    desc 'sessions SUBCOMMAND', 'Manage coding sessions'
    subcommand 'sessions', Class.new(Thor) {
      class_option :format, type: :string, default: 'table', enum: %w[table json], desc: 'Output format'

      desc 'list', 'List all sessions'
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
      option :source, required: true, desc: 'Source name (e.g., sources/github/owner/repo)'
      option :branch, default: 'main', desc: 'Starting branch'
      option :prompt, required: true, desc: 'Task prompt'
      option :title, desc: 'Session title'
      option :auto_pr, type: :boolean, default: false, desc: 'Auto-create PR when done'
      def create
        source_context = {
          'source' => options[:source],
          'githubRepoContext' => { 'startingBranch' => options[:branch] }
        }

        params = {
          prompt: options[:prompt],
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
      def approve(id)
        session = client.sessions.approve_plan(id)
        puts "Plan approved for session: #{session.name}"
        puts "State: #{session.state}"
      rescue JulesRuby::Error => e
        error_exit(e)
      end

      desc 'message ID', 'Send a message to a session'
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
        warn "Error: #{error.message}"
        exit 1
      end
    }

    desc 'activities SUBCOMMAND', 'View session activities'
    subcommand 'activities', Class.new(Thor) {
      class_option :format, type: :string, default: 'table', enum: %w[table json], desc: 'Output format'

      desc 'list SESSION_ID', 'List activities for a session'
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
        warn "Error: #{error.message}"
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
