# frozen_string_literal: true

require_relative 'prompts'

module JulesRuby
  # Interactive mode for jules-ruby CLI
  class Interactive
    # States that should trigger auto-refresh
    AUTO_REFRESH_STATES = %w[PLANNING IN_PROGRESS QUEUED].freeze
    AUTO_REFRESH_INTERVAL = 60 # seconds

    def initialize
      @client = JulesRuby::Client.new
      @prompt = Prompts.prompt
    end

    private

    def wrap_text(text, width = 76)
      return '' unless text

      text.gsub(/(.{1,#{width}})(\s+|$)/, "\\1\n").strip
    end

    # Select action with auto-refresh for active sessions
    # Returns the selected action or :refresh if timeout expires
    def select_with_auto_refresh(choices, session)
      if AUTO_REFRESH_STATES.include?(session.state)
        puts Prompts.rgb_color("  ⏱️  Auto-refresh in #{AUTO_REFRESH_INTERVAL}s (press any key for menu)", :purple)
        puts
        key = @prompt.keypress(timeout: AUTO_REFRESH_INTERVAL)
        return :refresh unless key

        # User pressed a key, show normal menu
        @prompt.select(Prompts.rgb_color('Action:', :lavender), choices, cycle: true)
      else
        @prompt.select(Prompts.rgb_color('Action:', :lavender), choices, cycle: true)
      end
    end

    def display_session_header(session)
      puts "  📋 #{Prompts.highlight(session.title || 'Session Details')} #{Prompts.state_emoji(session.state)}"
      puts "  #{Prompts.divider}"
      puts
      puts "  #{Prompts.rgb_color('ID:', :lavender)}      #{Prompts.rgb_color(session.id, :purple)}"
      puts "  #{Prompts.rgb_color('State:',
                                  :lavender)}   #{Prompts.rgb_color(Prompts.state_label(session.state), :purple)}"
      puts "  #{Prompts.rgb_color('Prompt:',
                                  :lavender)}  #{Prompts.rgb_color(session.prompt&.slice(0, 60),
                                                                   :purple)}#{if session.prompt && session.prompt.length > 60
                                                                                '...'
                                                                              end}"
      puts "  #{Prompts.rgb_color('URL:', :lavender)}     #{Prompts.rgb_color(session.url, :purple)}" if session.url
      puts "  #{Prompts.rgb_color('Created:',
                                  :lavender)} #{Prompts.rgb_color(Prompts.format_datetime(session.create_time),
                                                                  :purple)}"
      puts "  #{Prompts.rgb_color('Updated:',
                                  :lavender)} #{Prompts.rgb_color(Prompts.format_datetime(session.update_time),
                                                                  :purple)}"
    end

    def fetch_latest_activity(session)
      activities = Prompts.with_spinner('Loading latest activity...') do
        # API returns activities in chronological order (oldest first),
        # so we need to fetch all and take the last one to get the latest
        @client.activities.all(session.name)
      end
      activities&.last
    rescue StandardError
      # Session may be newly created with no activities yet, or API error
      nil
    end

    def display_latest_activity(latest_activity)
      return unless latest_activity

      puts
      puts "  📍 #{Prompts.highlight('Latest Activity')}"
      puts "  #{Prompts.divider}"
      time = Prompts.time_ago_in_words(latest_activity.create_time)
      type_str = latest_activity.type.to_s.gsub('_', ' ').capitalize
      puts Prompts.rgb_color("  #{type_str} (#{time})", :purple)
      puts
      display_activity_content(latest_activity)
    end

    def display_activity_content(activity)
      case activity.type
      when :agent_messaged, :user_messaged
        wrap_text(activity.message, 76).each_line { |line| puts Prompts.rgb_color("  #{line}", :purple) }
      when :plan_generated
        if activity.plan&.steps
          activity.plan.steps.each_with_index do |step, i|
            puts Prompts.rgb_color("  #{i + 1}. #{step.title}", :purple)
          end
        end
      when :progress_updated
        puts Prompts.rgb_color("  #{activity.progress_title}", :purple)
        puts Prompts.rgb_color("  #{activity.progress_description}", :purple) if activity.progress_description
      when :session_failed
        wrap_text(activity.failure_reason, 76).each_line { |line| puts Prompts.rgb_color("  #{line}", :purple) }
      when :session_completed
        puts Prompts.rgb_color('  Session completed successfully', :purple)
      end
    end

    def get_session_choices(session)
      choices = []
      if session.awaiting_plan_approval?
        choices << { name: "✅ #{Prompts.rgb_color('Approve Plan', :purple)}",
                     value: :approve }
      end
      choices << { name: "💬 #{Prompts.rgb_color('Send Message', :purple)}", value: :message }
      choices << { name: "📜 #{Prompts.rgb_color('View Activities', :purple)}", value: :activities }
      choices << { name: "🌐 #{Prompts.rgb_color('Open in Browser', :purple)}", value: :open_url } if session.url
      choices << { name: "🗑️  #{Prompts.rgb_color('Delete Session', :purple)}", value: :delete }
      choices << { name: "🔄 #{Prompts.rgb_color('Refresh', :purple)}", value: :refresh }
      choices << { name: "← #{Prompts.rgb_color('Back', :purple)}", value: :back }
      choices
    end

    def handle_session_action(action, session)
      case action
      when :approve
        approve_plan(session)
      when :message
        send_message(session)
      when :activities
        view_activities(session)
        :refresh
      when :open_url
        system('open', session.url) if session.url
        nil
      when :delete
        delete_session(session) ? :deleted : nil
      when :refresh
        refresh_session(session)
      when :back
        :back
      end
    end

    def approve_plan(session)
      Prompts.with_spinner('Approving plan...') do
        @client.sessions.approve_plan(session.name)
      end
      puts Prompts.rgb_color("\n  ✅ Plan approved!", :purple)
      @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
      @client.sessions.find(session.name)
    end

    def send_message(session)
      msg = @prompt.ask(Prompts.rgb_color('Message to send:', :lavender))
      return unless msg && !msg.empty?

      Prompts.with_spinner('Sending message...') do
        @client.sessions.send_message(session.name, prompt: msg)
      end
      puts Prompts.rgb_color("\n  ✅ Message sent!", :purple)
      @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
      @client.sessions.find(session.name)
    end

    def delete_session(session)
      return false unless @prompt.yes?(
        Prompts.rgb_color("Are you sure you want to delete session #{session.id}?", :lavender), default: false
      )

      Prompts.with_spinner('Deleting session...') do
        @client.sessions.destroy(session.name)
      end
      puts Prompts.rgb_color("\n  ✅ Session deleted!", :purple)
      @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
      true
    end

    def refresh_session(session)
      Prompts.with_spinner('Refreshing...') do
        @client.sessions.find(session.name)
      end
    end

    def display_activity_item(activity)
      time = Prompts.time_ago_in_words(activity.create_time)
      type_str = activity.type.to_s.gsub('_', ' ').capitalize

      puts
      puts Prompts.rgb_color("  ┌─ #{type_str} (#{time})", :muted)

      display_activity_box_content(activity)

      puts Prompts.rgb_color('  └─', :muted)
    end

    def display_activity_box_content(activity)
      case activity.type
      when :agent_messaged, :user_messaged
        if activity.message
          puts Prompts.rgb_color('  │', :muted)
          wrap_text(activity.message, 72).each_line do |line|
            puts "#{Prompts.rgb_color('  │', :muted)}  #{Prompts.rgb_color(line.chomp, :purple)}"
          end
        end
      when :plan_generated
        if activity.plan&.steps
          puts Prompts.rgb_color('  │', :muted)
          activity.plan.steps.each_with_index do |step, i|
            puts "#{Prompts.rgb_color('  │', :muted)}  #{Prompts.rgb_color("#{i + 1}. #{step.title}", :purple)}"
          end
        end
      when :progress_updated
        puts "#{Prompts.rgb_color('  │', :muted)}  #{Prompts.rgb_color(activity.progress_title, :purple)}"
        if activity.progress_description
          puts "#{Prompts.rgb_color('  │',
                                    :muted)}  #{Prompts.rgb_color(activity.progress_description,
                                                                  :purple)}"
        end
      when :session_failed
        puts Prompts.rgb_color('  │', :muted)
        wrap_text(activity.failure_reason, 72).each_line do |line|
          puts "#{Prompts.rgb_color('  │', :muted)}  #{Prompts.rgb_color(line.chomp, :purple)}"
        end
      when :session_completed
        puts "#{Prompts.rgb_color('  │', :muted)}  #{Prompts.rgb_color('Session completed successfully', :purple)}"
      end
    end

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
      puts "  #{Prompts.rgb_color('📦 Repository:',
                                  :lavender)} #{Prompts.rgb_color(source.github_repo&.full_name, :purple)}"
      puts "  #{Prompts.rgb_color('🌿 Branch:', :lavender)}     #{Prompts.rgb_color(branch, :purple)}"
      puts "  #{Prompts.rgb_color('📝 Prompt:',
                                  :lavender)}     #{Prompts.rgb_color(task_prompt.slice(0, 50),
                                                                      :purple)}#{'...' if task_prompt.length > 50}"
      puts "  #{Prompts.rgb_color('🏷️  Title:',
                                  :lavender)}      #{Prompts.rgb_color(title || '(auto-generated)', :purple)}"
      puts "  #{Prompts.rgb_color('🔄 Auto PR:', :lavender)}    #{Prompts.rgb_color(auto_pr ? 'Yes' : 'No', :purple)}"
      puts
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

    def update_session_state(session, result, needs_activity_fetch)
      if result.is_a?(JulesRuby::Models::Session)
        [result, true]
      elsif result == :refresh
        [session, true]
      else
        [session, needs_activity_fetch]
      end
    end

    public

    def start
      loop do
        Prompts.clear_screen
        Prompts.print_banner

        choice = @prompt.select(Prompts.rgb_color('What would you like to do?', :lavender), cycle: true) do |menu|
          menu.choice Prompts.rgb_color('Create new session', :purple), :create_session
          menu.choice Prompts.rgb_color('View sessions', :purple), :view_sessions
          menu.choice Prompts.rgb_color('Browse sources', :purple), :browse_sources
          menu.choice Prompts.rgb_color('Exit', :purple), :exit
        end

        case choice
        when :create_session
          create_session_wizard
        when :view_sessions
          view_sessions
        when :browse_sources
          browse_sources
        when :exit
          puts Prompts.rgb_color("\nGoodbye! 👋", :purple)
          break
        end
      end
    end

    def create_session_wizard
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

    def view_sessions
      loop do
        Prompts.clear_screen
        Prompts.print_banner

        sessions = Prompts.with_spinner('Loading sessions...') do
          @client.sessions.all
        end

        if sessions.empty?
          @prompt.warn(Prompts.rgb_color('No sessions found.', :purple))
          @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
          return
        end

        choices = sessions.map { |s| Prompts.format_session_choice(s) }
        choices.unshift({ name: "➕ #{Prompts.rgb_color('Create new session', :purple)}", value: :create })
        choices << { name: "← #{Prompts.rgb_color('Back to main menu', :purple)}", value: :back }

        session = @prompt.select(
          Prompts.rgb_color('Select a session to view:', :lavender),
          choices,
          per_page: 15,
          cycle: true
        )

        break if session == :back

        if session == :create
          create_session_wizard
          next
        end

        session_detail(session)
      end
    end

    def session_detail(session)
      needs_activity_fetch = true

      loop do
        Prompts.clear_screen
        Prompts.print_banner

        display_session_header(session)

        if needs_activity_fetch
          latest_activity = fetch_latest_activity(session)
          needs_activity_fetch = false
        end

        display_latest_activity(latest_activity)
        puts

        choices = get_session_choices(session)
        action = select_with_auto_refresh(choices, session)

        result = handle_session_action(action, session)
        break if result == :back
        break if result == :deleted

        session, needs_activity_fetch = update_session_state(session, result, needs_activity_fetch)
      end
    end

    def view_activities(session)
      Prompts.clear_screen
      Prompts.print_banner

      activities = Prompts.with_spinner('Loading activities...') do
        @client.activities.all(session.name)
      end

      if activities.empty?
        @prompt.warn(Prompts.rgb_color('No activities found.', :purple))
        @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
        return
      end

      activities.each do |activity|
        display_activity_item(activity)
      end

      puts
      @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
    end

    def browse_sources
      Prompts.clear_screen
      Prompts.print_banner

      sources = Prompts.with_spinner('Loading sources...') do
        @client.sources.all
      end

      if sources.empty?
        @prompt.warn(Prompts.rgb_color('No sources found.', :purple))
        @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
        return
      end

      choices = sources.map { |s| Prompts.format_source_choice(s) }
      choices << { name: "← #{Prompts.rgb_color('Back to main menu', :purple)}", value: :back }

      source = @prompt.select(
        Prompts.rgb_color('Select a source to view:', :lavender),
        choices,
        filter: true,
        per_page: 15,
        cycle: true
      )

      return if source == :back

      puts
      puts "  #{Prompts.rgb_color('Name:', :lavender)}       #{Prompts.rgb_color(source.name, :purple)}"
      puts "  #{Prompts.rgb_color('ID:', :lavender)}         #{Prompts.rgb_color(source.id, :purple)}"
      puts "  #{Prompts.rgb_color('Repository:',
                                  :lavender)} #{Prompts.rgb_color(source.github_repo&.full_name, :purple)}"
      puts

      @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
    end
  end
end
