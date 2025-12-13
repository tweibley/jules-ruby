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
        puts "  ⏱️  Auto-refresh in #{AUTO_REFRESH_INTERVAL}s (press any key for menu)"
        puts
        key = @prompt.keypress(timeout: AUTO_REFRESH_INTERVAL)
        return :refresh unless key

        # User pressed a key, show normal menu
        @prompt.select('Action:', choices, cycle: true)
      else
        @prompt.select('Action:', choices, cycle: true)
      end
    end

    def display_session_header(session)
      puts "  📋 #{session.title || 'Session Details'} #{Prompts.state_emoji(session.state)}"
      puts "  #{'─' * 50}"
      puts
      puts "  ID:      #{session.id}"
      puts "  State:   #{Prompts.state_label(session.state)}"
      puts "  Prompt:  #{session.prompt&.slice(0, 60)}#{'...' if session.prompt && session.prompt.length > 60}"
      puts "  URL:     #{session.url}" if session.url
      puts "  Created: #{Prompts.format_datetime(session.create_time)}"
      puts "  Updated: #{Prompts.format_datetime(session.update_time)}"
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
      puts '  📍 Latest Activity'
      puts '  ─────────────────────────────────────'
      time = Prompts.time_ago_in_words(latest_activity.create_time)
      type_str = latest_activity.type.to_s.gsub('_', ' ').capitalize
      puts "  #{type_str} (#{time})"
      puts
      display_activity_content(latest_activity)
    end

    def display_activity_content(activity)
      case activity.type
      when :agent_messaged, :user_messaged
        wrap_text(activity.message, 76).each_line { |line| puts "  #{line}" }
      when :plan_generated
        if activity.plan&.steps
          activity.plan.steps.each_with_index do |step, i|
            puts "  #{i + 1}. #{step.title}"
          end
        end
      when :progress_updated
        puts "  #{activity.progress_title}"
        puts "  #{activity.progress_description}" if activity.progress_description
      when :session_failed
        wrap_text(activity.failure_reason, 76).each_line { |line| puts "  #{line}" }
      when :session_completed
        puts '  Session completed successfully'
      end
    end

    def get_session_choices(session)
      choices = []
      choices << { name: '✅ Approve Plan', value: :approve } if session.awaiting_plan_approval?
      choices << { name: '💬 Send Message', value: :message }
      choices << { name: '📜 View Activities', value: :activities }
      choices << { name: '🌐 Open in Browser', value: :open_url } if session.url
      choices << { name: '🗑️  Delete Session', value: :delete }
      choices << { name: '🔄 Refresh', value: :refresh }
      choices << { name: '← Back', value: :back }
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
      puts "\n  ✅ Plan approved!"
      @prompt.keypress('Press any key to continue...')
      @client.sessions.find(session.name)
    end

    def send_message(session)
      msg = @prompt.ask('Message to send:')
      return unless msg && !msg.empty?

      Prompts.with_spinner('Sending message...') do
        @client.sessions.send_message(session.name, prompt: msg)
      end
      puts "\n  ✅ Message sent!"
      @prompt.keypress('Press any key to continue...')
      @client.sessions.find(session.name)
    end

    def delete_session(session)
      return false unless @prompt.yes?("Are you sure you want to delete session #{session.id}?", default: false)

      Prompts.with_spinner('Deleting session...') do
        @client.sessions.destroy(session.name)
      end
      puts "\n  ✅ Session deleted!"
      @prompt.keypress('Press any key to continue...')
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
      puts "  ┌─ #{type_str} (#{time})"

      display_activity_box_content(activity)

      puts '  └─'
    end

    def display_activity_box_content(activity)
      case activity.type
      when :agent_messaged, :user_messaged
        if activity.message
          puts '  │'
          wrap_text(activity.message, 72).each_line { |line| puts "  │  #{line}" }
        end
      when :plan_generated
        if activity.plan&.steps
          puts '  │'
          activity.plan.steps.each_with_index do |step, i|
            puts "  │  #{i + 1}. #{step.title}"
          end
        end
      when :progress_updated
        puts "  │  #{activity.progress_title}"
        puts "  │  #{activity.progress_description}" if activity.progress_description
      when :session_failed
        puts '  │'
        wrap_text(activity.failure_reason, 72).each_line { |line| puts "  │  #{line}" }
      when :session_completed
        puts '  │  Session completed successfully'
      end
    end

    def select_source
      sources = Prompts.with_spinner('Loading sources...') do
        @client.sources.all
      end

      if sources.empty?
        @prompt.error('No sources found. Please connect a repository first.')
        @prompt.keypress('Press any key to continue...')
        return nil
      end

      source_choices = sources.map { |s| Prompts.format_source_choice(s) }
      @prompt.select(
        'Select a repository:',
        source_choices,
        filter: true,
        per_page: 15
      )
    end

    def ask_for_prompt
      puts
      @prompt.ask('What would you like Jules to do?') do |q|
        q.required true
        q.validate(/\S/, 'Prompt cannot be empty')
      end
    end

    def display_session_summary(source, branch, task_prompt, title, auto_pr)
      puts
      puts '  📋 Session Summary'
      puts '  ─────────────────────────────────────'
      puts "  📦 Repository: #{source.github_repo&.full_name}"
      puts "  🌿 Branch:     #{branch}"
      puts "  📝 Prompt:     #{task_prompt.slice(0, 50)}#{'...' if task_prompt.length > 50}"
      puts "  🏷️  Title:      #{title || '(auto-generated)'}"
      puts "  🔄 Auto PR:    #{auto_pr ? 'Yes' : 'No'}"
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
      puts "  ✅ Session created: #{session.name}"
      puts "  🔗 URL: #{session.url}"
      puts "  📊 State: #{session.state}"
      puts

      @prompt.keypress('Press any key to continue...')
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

        choice = @prompt.select('What would you like to do?', cycle: true) do |menu|
          menu.choice 'Create new session', :create_session
          menu.choice 'View sessions', :view_sessions
          menu.choice 'Browse sources', :browse_sources
          menu.choice 'Exit', :exit
        end

        case choice
        when :create_session
          create_session_wizard
        when :view_sessions
          view_sessions
        when :browse_sources
          browse_sources
        when :exit
          puts "\nGoodbye! 👋"
          break
        end
      end
    end

    def create_session_wizard
      Prompts.clear_screen
      Prompts.print_banner

      source = select_source
      return unless source

      branch = @prompt.ask('Starting branch:', default: 'main')

      task_prompt = ask_for_prompt

      title = @prompt.ask('Session title (optional):')
      auto_pr = @prompt.yes?('Auto-create PR when done?', default: true)

      display_session_summary(source, branch, task_prompt, title, auto_pr)

      return unless @prompt.yes?('Create this session?', default: true)

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
          @prompt.warn('No sessions found.')
          @prompt.keypress('Press any key to continue...')
          return
        end

        choices = sessions.map { |s| Prompts.format_session_choice(s) }
        choices.unshift({ name: '➕ Create new session', value: :create })
        choices << { name: '← Back to main menu', value: :back }

        session = @prompt.select(
          'Select a session to view:',
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
        @prompt.warn('No activities found.')
        @prompt.keypress('Press any key to continue...')
        return
      end

      activities.each do |activity|
        display_activity_item(activity)
      end

      puts
      @prompt.keypress('Press any key to continue...')
    end

    def browse_sources
      Prompts.clear_screen
      Prompts.print_banner

      sources = Prompts.with_spinner('Loading sources...') do
        @client.sources.all
      end

      if sources.empty?
        @prompt.warn('No sources found.')
        @prompt.keypress('Press any key to continue...')
        return
      end

      choices = sources.map { |s| Prompts.format_source_choice(s) }
      choices << { name: '← Back to main menu', value: :back }

      source = @prompt.select(
        'Select a source to view:',
        choices,
        filter: true,
        per_page: 15,
        cycle: true
      )

      return if source == :back

      puts
      puts "  Name:       #{source.name}"
      puts "  ID:         #{source.id}"
      puts "  Repository: #{source.github_repo&.full_name}"
      puts

      @prompt.keypress('Press any key to continue...')
    end
  end
end
