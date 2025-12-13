# frozen_string_literal: true

require_relative '../prompts'

module JulesRuby
  class Interactive
    # Renders activity items in the interactive CLI
    class ActivityRenderer
      def render(activity)
        time = Prompts.time_ago_in_words(activity.create_time)
        type_str = activity.type.to_s.gsub('_', ' ').capitalize

        puts
        puts Prompts.rgb_color("  ┌─ #{type_str} (#{time})", :muted)

        display_activity_box_content(activity)

        puts Prompts.rgb_color('  └─', :muted)
      end

      private

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

      def wrap_text(text, width = 76)
        return '' unless text

        text.gsub(/(.{1,#{width}})(\s+|$)/, "\\1\n").strip
      end
    end
  end
end
