# frozen_string_literal: true

require 'time'
require_relative 'base'

module JulesRuby
  module Commands
    # Sessions subcommand
    class Sessions < Base
      desc 'list', 'List all sessions'
      format_option
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
      format_option
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

        session = create_session(prompt_text)
        print_creation_success(session)
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

      def create_session(prompt_text)
        params = build_create_params(prompt_text)
        client.sessions.create(**params)
      end

      def build_create_params(prompt_text)
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
        params
      end

      def print_creation_success(session)
        puts "Session created: #{session.name}"
        puts "URL: #{session.url}"
        puts "State: #{session.state}"
      end

      def print_sessions_table(sessions)
        if sessions.empty?
          puts 'No sessions found.'
          return
        end
        puts 'ID                   TITLE                          STATE                UPDATED        '
        puts '-' * 90
        sessions.each do |s|
          title = truncate(s.title || s.prompt, 28)
          # Optimization: Use Time.iso8601 instead of Time.parse for ~3x faster parsing
          updated = s.update_time ? Time.iso8601(s.update_time).strftime('%Y-%m-%d %H:%M') : 'N/A'
          puts format('%<id>-20s %<title>-30s %<state>-20s %<updated>-15s',
                      id: s.id, title: title, state: s.state, updated: updated)
        end
      end

      def print_session_details(session)
        print_session_basic_info(session)
        print_session_outputs(session.outputs) if session.outputs&.any?
      end

      def print_session_basic_info(session)
        puts "Name:    #{session.name}"
        puts "ID:      #{session.id}"
        puts "Title:   #{session.title}" if session.title
        puts "Prompt:  #{session.prompt}"
        puts "State:   #{session.state}"
        puts "URL:     #{session.url}" if session.url
        puts "Created: #{session.create_time}"
        puts "Updated: #{session.update_time}"
      end

      def print_session_outputs(outputs)
        puts "\nOutputs:"
        outputs.each do |output|
          if output.respond_to?(:url)
            puts "  - PR: #{output.url}"
          else
            puts "  - #{output}"
          end
        end
      end
    end
  end
end
