# frozen_string_literal: true

require_relative 'base'

module JulesRuby
  module Commands
    # Activities subcommand
    class Activities < Base
      desc 'list SESSION_ID', 'List activities for a session'
      long_desc <<~LONGDESC
        List all activities for a session (messages, plans, progress updates).

        Example:
          $ jules-ruby activities list SESSION_ID
      LONGDESC
      format_option
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
      long_desc <<~LONGDESC
        Show details for a specific activity.

        Example:
          $ jules-ruby activities show sessions/SESSION_ID/activities/ACTIVITY_ID
      LONGDESC
      format_option
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

      def print_activities_table(activities)
        if activities.empty?
          puts 'No activities found.'
          return
        end
        puts 'ID                   TYPE                 FROM       DESCRIPTION                             '
        puts '-' * 95
        activities.each do |a|
          desc = truncate(activity_summary(a), 38)
          puts format('%<id>-20s %<type>-20s %<originator>-10s %<desc>-40s',
                      id: a.id, type: a.type, originator: a.originator || 'N/A', desc: desc)
        end
      end

      def print_activity_details(activity)
        print_activity_header(activity)
        print_activity_content(activity)
        print_activity_artifacts(activity.artifacts) if activity.artifacts&.any?
      end

      def print_activity_header(activity)
        puts "Name:        #{activity.name}"
        puts "ID:          #{activity.id}"
        puts "Type:        #{activity.type}"
        puts "Originator:  #{activity.originator}"
        puts "Created:     #{activity.create_time}"
        puts "Description: #{activity.description}" if activity.description
      end

      def print_activity_content(activity)
        case activity.type
        when :agent_messaged, :user_messaged
          print_message(activity)
        when :plan_generated
          print_plan(activity)
        when :progress_updated
          print_progress(activity)
        when :session_failed
          puts "\nFailure Reason: #{activity.failure_reason}"
        end
      end

      def print_message(activity)
        puts "\nMessage:"
        puts "  #{activity.message}"
      end

      def print_plan(activity)
        return unless activity.plan

        puts "\nPlan:"
        activity.plan.steps&.each_with_index do |step, i|
          puts "  #{i + 1}. #{step.title}"
        end
      end

      def print_progress(activity)
        puts "\nProgress: #{activity.progress_title}"
        puts "Details:  #{activity.progress_description}" if activity.progress_description
      end

      def print_activity_artifacts(artifacts)
        puts "\nArtifacts:"
        artifacts.each do |artifact|
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
        else
          summary_for_state(activity)
        end
      end

      def summary_for_state(activity)
        case activity.type
        when :session_completed
          'Session completed'
        when :session_failed
          activity.failure_reason || 'Session failed'
        else
          activity.description || ''
        end
      end
    end
  end
end
