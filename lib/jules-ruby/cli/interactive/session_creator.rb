# frozen_string_literal: true

require_relative '../prompts'

module JulesRuby
  class Interactive
    # Wizard for creating new sessions
    class SessionCreator
      def initialize(client, prompt)
        @client = client
        @prompt = prompt
      end

      def run
        Prompts.clear_screen
        Prompts.print_banner

        source = select_source
        return unless source

        branch = @prompt.ask(Prompts.rgb_color('Starting branch:', :lavender), default: 'main')
        task_prompt = ask_for_prompt
        title = @prompt.ask(Prompts.rgb_color('Session title (optional):', :lavender))
        auto_pr = @prompt.yes?(Prompts.rgb_color('Auto-create PR when done?', :lavender), default: true)

        display_session_summary(source, branch, task_prompt, title, auto_pr)

        return unless @prompt.yes?(Prompts.rgb_color('Create this session?', :lavender), default: true)

        create_and_display_session(source, branch, task_prompt, title, auto_pr)
      end

      private

      def select_source
        sources = Prompts.with_spinner('Loading sources...') do
          @client.sources.all
        end

        if sources.empty?
          @prompt.error(Prompts.rgb_color('No sources found. Please connect a repository first.', :purple))
          @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
          return nil
        end

        source_choices = sources.map { |s| Prompts.format_source_choice(s) }
        @prompt.select(
          Prompts.rgb_color('Select a repository:', :lavender),
          source_choices,
          filter: true,
          per_page: 15
        )
      end

      def ask_for_prompt
        puts
        @prompt.ask(Prompts.rgb_color('What would you like Jules to do?', :lavender)) do |q|
          q.required true
          q.validate(/\S/, 'Prompt cannot be empty')
        end
      end

      def display_session_summary(source, branch, task_prompt, title, auto_pr)
        puts
        puts "  📋 #{Prompts.highlight('Session Summary')}"
        puts "  #{Prompts.divider}"
        display_summary_field('📦 Repository:', source.github_repo&.full_name)
        display_summary_field('🌿 Branch:', branch)
        display_summary_field('📝 Prompt:', truncate(task_prompt, 50))
        display_summary_field('🏷️  Title:', title || '(auto-generated)')
        display_summary_field('🔄 Auto PR:', auto_pr ? 'Yes' : 'No')
        puts
      end

      def display_summary_field(label, value)
        puts "  #{Prompts.rgb_color(label, :lavender)} #{Prompts.rgb_color(value, :purple)}"
      end

      def create_and_display_session(source, branch, task_prompt, title, auto_pr)
        session = Prompts.with_spinner('Creating session...') do
          source_context = {
            'source' => source.name,
            'githubRepoContext' => { 'startingBranch' => branch }
          }

          params = {
            prompt: task_prompt,
            source_context: source_context
          }
          params[:title] = title if title && !title.empty?
          params[:automation_mode] = 'AUTO_CREATE_PR' if auto_pr

          @client.sessions.create(**params)
        end

        puts
        puts Prompts.rgb_color("  ✅ Session created: #{session.name}", :purple)
        puts Prompts.rgb_color("  🔗 URL: #{session.url}", :purple)
        puts Prompts.rgb_color("  📊 State: #{session.state}", :purple)
        puts

        @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
      end

      def truncate(str, length)
        return '' unless str

        str.length > length ? "#{str[0...(length - 3)]}..." : str
      end
    end
  end
end
