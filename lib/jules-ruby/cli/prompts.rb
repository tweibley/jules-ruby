# frozen_string_literal: true

require 'pastel'
require 'tty-prompt'
require 'tty-spinner'
require_relative 'banner'

module JulesRuby
  # Helper methods for interactive prompts
  module Prompts
    # Custom true-color RGB theme matching Jules CLI design
    PASTEL = Pastel.new

    # RGB color values matching the reference CLI screenshot
    COLORS = {
      purple: [147, 112, 219],     # Selection highlight #9370DB
      lavender: [196, 181, 253],   # Accent text #C4B5FD
      muted: [139, 92, 246],       # Muted purple #8B5CF6
      dim: [107, 114, 128]         # Dim gray #6B7280
    }.freeze

    # Define custom symbols for the prompt
    PROMPT_SYMBOLS = {
      marker: '❯',
      radio_on: '◉',
      radio_off: '◯'
    }.freeze

    # State emoji indicators
    STATE_EMOJI = {
      'QUEUED' => '⏳',
      'PLANNING' => '🔵',
      'AWAITING_PLAN_APPROVAL' => '🟡',
      'AWAITING_USER_FEEDBACK' => '🟠',
      'IN_PROGRESS' => '🔵',
      'PAUSED' => '⏸️',
      'FAILED' => '🔴',
      'COMPLETED' => '🟢'
    }.freeze

    STATE_LABELS = {
      'QUEUED' => 'Queued',
      'PLANNING' => 'Planning',
      'AWAITING_PLAN_APPROVAL' => 'Needs Approval',
      'AWAITING_USER_FEEDBACK' => 'Needs Feedback',
      'IN_PROGRESS' => 'Working',
      'PAUSED' => 'Paused',
      'FAILED' => 'Failed',
      'COMPLETED' => 'Done'
    }.freeze

    class << self
      # Apply true-color RGB to text using ANSI escape sequences
      def rgb_color(text, color_name)
        r, g, b = COLORS[color_name]
        # Sanitize input to prevent ANSI injection
        safe_text = PASTEL.strip(text.to_s)
        "\e[38;2;#{r};#{g};#{b}m#{safe_text}\e[0m"
      end

      def prompt
        @prompt ||= TTY::Prompt.new(
          interrupt: :exit,
          symbols: PROMPT_SYMBOLS,
          active_color: :magenta,
          help_color: :cyan
        )
      end

      def spinner(message)
        TTY::Spinner.new(
          "[:spinner] #{rgb_color(message, :purple)}",
          format: :dots,
          success_mark: PASTEL.green('✓'),
          error_mark: PASTEL.red('✗')
        )
      end

      def with_spinner(message)
        spin = spinner(message)
        spin.auto_spin
        result = yield
        spin.success(PASTEL.green('done'))
        result
      rescue StandardError => e
        spin.error(PASTEL.red('failed'))
        raise e
      end

      def state_emoji(state)
        # API returns nil for completed sessions
        return '🟢' if state.nil?

        STATE_EMOJI[state] || '❓'
      end

      def state_label(state)
        # API returns nil for completed sessions
        return 'Completed' if state.nil?

        STATE_LABELS[state] || state
      end

      def format_session_choice(session)
        emoji = state_emoji(session.state)
        label = state_label(session.state)
        title = session.title || session.prompt&.slice(0, 25) || 'Untitled'
        title = "#{title[0..22]}..." if title.length > 25
        time_ago = time_ago_in_words(session.update_time)
        {
          name: "#{emoji} #{rgb_color(title.ljust(27),
                                      :purple)} #{rgb_color(label.ljust(15), :lavender)} #{rgb_color(time_ago, :dim)}",
          value: session
        }
      end

      def format_source_choice(source)
        repo_name = source.github_repo&.full_name || source.name
        {
          name: rgb_color(repo_name, :purple),
          value: source
        }
      end

      def time_ago_in_words(time_string)
        return 'N/A' unless time_string

        time = Time.parse(time_string)
        diff = Time.now - time
        case diff
        when 0..59
          'just now'
        when 60..3599
          "#{(diff / 60).to_i}m ago"
        when 3600..86_399
          "#{(diff / 3600).to_i}h ago"
        else
          "#{(diff / 86_400).to_i}d ago"
        end
      end

      def format_datetime(time_string)
        return 'N/A' unless time_string

        time = Time.parse(time_string)
        today = Time.now.to_date
        date = time.to_date

        if date == today
          "Today #{time.strftime('%l:%M %p').strip}"
        elsif date == today - 1
          "Yesterday #{time.strftime('%l:%M %p').strip}"
        else
          time.strftime('%b %d, %Y %l:%M %p').strip
        end
      end

      def clear_screen
        print "\e[2J\e[H"
      end

      def header(title)
        puts
        puts "  🚀 #{rgb_color(title, :lavender)}"
        puts "  #{rgb_color('─' * 50, :muted)}"
        puts
      end

      def divider
        rgb_color('─' * 50, :muted)
      end

      def highlight(text)
        rgb_color(text, :lavender)
      end

      def muted(text)
        rgb_color(text, :dim)
      end

      def print_banner
        Banner.print_banner
      end
    end
  end
end
