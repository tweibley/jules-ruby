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
      end

      # User pressed a key or session not auto-refreshable, show normal menu
      @prompt.select(Prompts.rgb_color('Action:', :lavender), choices, cycle: true)
    end

    def display_session_header(session)
      display_title_line(session)
      puts "  #{Prompts.divider}"
      puts
      display_header_field('ID:', session.id)
      display_header_field('State:', Prompts.state_label(session.state))
      display_header_field('Prompt:', truncate(session.prompt, 60))
      display_header_field('URL:', session.url) if session.url
      display_header_field('Created:', Prompts.format_datetime(session.create_time))
      display_header_field('Updated:', Prompts.format_datetime(session.update_time))
    end

    def display_title_line(session)
      puts "  📋 #{Prompts.highlight(session.title || 'Session Details')} #{Prompts.state_emoji(session.state)}"
    end

    def display_header_field(label, value)
      puts "  #{Prompts.rgb_color(label, :lavender)} #{Prompts.rgb_color(value, :purple)}"
    end

    def truncate(text, length)
      return '' unless text
      return text if text.length <= length

      "#{text.slice(0, length)}..."
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
        display_plan_simple(activity)
      when :progress_updated
        puts Prompts.rgb_color("  #{activity.progress_title}", :purple)
        puts Prompts.rgb_color("  #{activity.progress_description}", :purple) if activity.progress_description
      when :session_failed
        wrap_text(activity.failure_reason, 76).each_line { |line| puts Prompts.rgb_color("  #{line}", :purple) }
      when :session_completed
        puts Prompts.rgb_color('  Session completed successfully', :purple)
      end
    end

    def display_plan_simple(activity)
      return unless activity.plan&.steps

      activity.plan.steps.each_with_index do |step, i|
        puts Prompts.rgb_color("  #{i + 1}. #{step.title}", :purple)
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
      when :approve then approve_plan(session)
      when :message then send_message(session)
      when :activities
        view_activities(session)
        :refresh
      when :open_url
        system('open', session.url) if session.url
        nil
      when :delete then delete_session?(session) ? :deleted : nil
      when :refresh then refresh_session(session)
      when :back then :back
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

    def delete_session?(session)
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
        display_message_box(activity)
      when :plan_generated
        display_plan_box(activity)
      when :progress_updated
        display_progress_box(activity)
      when :session_failed
        display_failure_box(activity)
      when :session_completed
        display_completion_box
      end
    end

    def display_message_box(activity)
      return unless activity.message

      puts Prompts.rgb_color('  │', :muted)
      wrap_text(activity.message, 72).each_line do |line|
        puts "#{Prompts.rgb_color('  │', :muted)}  #{Prompts.rgb_color(line.chomp, :purple)}"
      end
    end

    def display_plan_box(activity)
      return unless activity.plan&.steps

      puts Prompts.rgb_color('  │', :muted)
      activity.plan.steps.each_with_index do |step, i|
        puts "#{Prompts.rgb_color('  │', :muted)}  #{Prompts.rgb_color("#{i + 1}. #{step.title}", :purple)}"
      end
    end

    def display_progress_box(activity)
      puts "#{Prompts.rgb_color('  │', :muted)}  #{Prompts.rgb_color(activity.progress_title, :purple)}"
      return unless activity.progress_description

      puts "#{Prompts.rgb_color('  │', :muted)}  #{Prompts.rgb_color(activity.progress_description, :purple)}"
    end

    def display_failure_box(activity)
      puts Prompts.rgb_color('  │', :muted)
      wrap_text(activity.failure_reason, 72).each_line do |line|
        puts "#{Prompts.rgb_color('  │', :muted)}  #{Prompts.rgb_color(line.chomp, :purple)}"
      end
    end

    def display_completion_box
      puts "#{Prompts.rgb_color('  │', :muted)}  #{Prompts.rgb_color('Session completed successfully', :purple)}"
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

        choice = main_menu_selection

        case choice
        when :create_session then create_session_wizard
        when :view_sessions then view_sessions
        when :browse_sources then browse_sources
        when :exit
          puts Prompts.rgb_color("\nGoodbye! 👋", :purple)
          break
        end
      end
    end

    def main_menu_selection
      @prompt.select(Prompts.rgb_color('What would you like to do?', :lavender), cycle: true) do |menu|
        menu.choice Prompts.rgb_color('Create new session', :purple), :create_session
        menu.choice Prompts.rgb_color('View sessions', :purple), :view_sessions
        menu.choice Prompts.rgb_color('Browse sources', :purple), :browse_sources
        menu.choice Prompts.rgb_color('Exit', :purple), :exit
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

        sessions = fetch_sessions
        return if sessions.empty?

        session = select_session(sessions)
        break if session == :back

        if session == :create
          create_session_wizard
        else
          session_detail(session)
        end
      end
    end

    def fetch_sessions
      sessions = Prompts.with_spinner('Loading sessions...') { @client.sessions.all }
      if sessions.empty?
        @prompt.warn(Prompts.rgb_color('No sessions found.', :purple))
        @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
      end
      sessions
    end

    def select_session(sessions)
      choices = sessions.map { |s| Prompts.format_session_choice(s) }
      choices.unshift({ name: "➕ #{Prompts.rgb_color('Create new session', :purple)}", value: :create })
      choices << { name: "← #{Prompts.rgb_color('Back to main menu', :purple)}", value: :back }

      @prompt.select(
        Prompts.rgb_color('Select a session to view:', :lavender),
        choices,
        per_page: 15,
        cycle: true
      )
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

      activities = Prompts.with_spinner('Loading activities...') { @client.activities.all(session.name) }

      if activities.empty?
        @prompt.warn(Prompts.rgb_color('No activities found.', :purple))
        @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
        return
      end

      activities.each { |activity| display_activity_item(activity) }
      puts
      @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
    end

    def browse_sources
      Prompts.clear_screen
      Prompts.print_banner

      sources = fetch_sources
      return if sources.empty?

      source = select_source_to_view(sources)
      return if source == :back

      display_source_details(source)
    end

    def fetch_sources
      sources = Prompts.with_spinner('Loading sources...') { @client.sources.all }
      if sources.empty?
        @prompt.warn(Prompts.rgb_color('No sources found.', :purple))
        @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
      end
      sources
    end

    def select_source_to_view(sources)
      choices = sources.map { |s| Prompts.format_source_choice(s) }
      choices << { name: "← #{Prompts.rgb_color('Back to main menu', :purple)}", value: :back }

      @prompt.select(
        Prompts.rgb_color('Select a source to view:', :lavender),
        choices,
        filter: true,
        per_page: 15,
        cycle: true
      )
    end

    def display_source_details(source)
      puts
      puts "  #{Prompts.rgb_color('Name:', :lavender)}       #{Prompts.rgb_color(source.name, :purple)}"
      puts "  #{Prompts.rgb_color('ID:', :lavender)}         #{Prompts.rgb_color(source.id, :purple)}"

      repo_label = Prompts.rgb_color('Repository:', :lavender)
      repo_val = Prompts.rgb_color(source.github_repo&.full_name, :purple)
      puts "  #{repo_label} #{repo_val}"
      puts

      @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
    end
  end
end
