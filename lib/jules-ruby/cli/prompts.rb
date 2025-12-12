# frozen_string_literal: true

require 'tty-prompt'
require 'tty-spinner'
require_relative 'banner'

module JulesRuby
  # Helper methods for interactive prompts
  module Prompts
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
      def prompt
        @prompt ||= TTY::Prompt.new(interrupt: :exit)
      end

      def spinner(message)
        TTY::Spinner.new("[:spinner] #{message}", format: :dots)
      end

      def with_spinner(message)
        spin = spinner(message)
        spin.auto_spin
        result = yield
        spin.success('done')
        result
      rescue StandardError => e
        spin.error('failed')
        raise e
      end

      def state_emoji(state)
        STATE_EMOJI[state] || '❓'
      end

      def state_label(state)
        STATE_LABELS[state] || state
      end

      def format_session_choice(session)
        emoji = state_emoji(session.state)
        label = state_label(session.state)
        title = session.title || session.prompt&.slice(0, 25) || 'Untitled'
        title = "#{title[0..22]}..." if title.length > 25
        time_ago = time_ago_in_words(session.update_time)
        {
          name: "#{emoji} #{title.ljust(27)} #{label.ljust(15)} #{time_ago}",
          value: session
        }
      end

      def format_source_choice(source)
        repo_name = source.github_repo&.full_name || source.name
        {
          name: repo_name,
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
        puts "  🚀 #{title}"
        puts "  #{'─' * 50}"
        puts
      end

      def print_banner
        Banner.print_banner
      end
    end
  end
end
