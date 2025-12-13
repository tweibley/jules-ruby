# frozen_string_literal: true

require_relative '../prompts'
require_relative 'activity_renderer'
require_relative 'session_creator'

module JulesRuby
  class Interactive
    # Manages viewing and interacting with sessions
    class SessionManager
      # States that should trigger auto-refresh
      AUTO_REFRESH_STATES = %w[PLANNING IN_PROGRESS QUEUED].freeze
      AUTO_REFRESH_INTERVAL = 60 # seconds

      def initialize(client, prompt)
        @client = client
        @prompt = prompt
        @activity_renderer = ActivityRenderer.new
      end

      def run
        loop do
          Prompts.clear_screen
          Prompts.print_banner

          sessions = fetch_sessions
          return if sessions.empty?

          session = select_session(sessions)
          break if session == :back

          if session == :create
            SessionCreator.new(@client, @prompt).run
          else
            session_detail(session)
          end
        end
      end

      private

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

      def fetch_latest_activity(session)
        activities = Prompts.with_spinner('Loading latest activity...') do
          @client.activities.all(session.name)
        end
        activities&.last
      rescue StandardError
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
        # Reuse ActivityRenderer logic? Or just minimal display for header?
        # The original code had simplified display.
        # "display_plan_simple" etc.
        # I'll adapt the original simple display logic here or use ActivityRenderer.
        # The original code had specific `display_activity_content` separate from `display_activity_box_content`.

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
          choices << { name: "✅ #{Prompts.rgb_color('Approve Plan', :purple)}", value: :approve }
        end
        choices << { name: "💬 #{Prompts.rgb_color('Send Message', :purple)}", value: :message }
        choices << { name: "📜 #{Prompts.rgb_color('View Activities', :purple)}", value: :activities }
        choices << { name: "🌐 #{Prompts.rgb_color('Open in Browser', :purple)}", value: :open_url } if session.url
        choices << { name: "🗑️  #{Prompts.rgb_color('Delete Session', :purple)}", value: :delete }
        choices << { name: "🔄 #{Prompts.rgb_color('Refresh', :purple)}", value: :refresh }
        choices << { name: "← #{Prompts.rgb_color('Back', :purple)}", value: :back }
        choices
      end

      def select_with_auto_refresh(choices, session)
        if AUTO_REFRESH_STATES.include?(session.state)
          puts Prompts.rgb_color("  ⏱️  Auto-refresh in #{AUTO_REFRESH_INTERVAL}s (press any key for menu)", :purple)
          puts
          key = @prompt.keypress(timeout: AUTO_REFRESH_INTERVAL)
          return :refresh unless key
        end

        @prompt.select(Prompts.rgb_color('Action:', :lavender), choices, cycle: true)
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

      def view_activities(session)
        Prompts.clear_screen
        Prompts.print_banner

        activities = Prompts.with_spinner('Loading activities...') { @client.activities.all(session.name) }

        if activities.empty?
          @prompt.warn(Prompts.rgb_color('No activities found.', :purple))
          @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
          return
        end

        activities.each { |activity| @activity_renderer.render(activity) }
        puts
        @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
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

      def update_session_state(session, result, needs_activity_fetch)
        if result.is_a?(JulesRuby::Models::Session)
          [result, true]
        elsif result == :refresh
          [session, true]
        else
          [session, needs_activity_fetch]
        end
      end

      def wrap_text(text, width = 76)
        return '' unless text

        text.gsub(/(.{1,#{width}})(\s+|$)/, "\\1\n").strip
      end

      def truncate(text, length)
        return '' unless text
        return text if text.length <= length

        "#{text.slice(0, length)}..."
      end
    end
  end
end
