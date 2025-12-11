# frozen_string_literal: true

module JulesRuby
  module Models
    class Activity
      ORIGINATORS = %w[user agent system].freeze

      attr_reader :name, :id, :description, :create_time, :originator, :artifacts,
                  :agent_messaged, :user_messaged, :plan_generated, :plan_approved,
                  :progress_updated, :session_completed, :session_failed

      def initialize(data)
        @name = data['name']
        @id = data['id']
        @description = data['description']
        @create_time = data['createTime']
        @originator = data['originator']
        @artifacts = (data['artifacts'] || []).map { |a| Artifact.new(a) }

        # Activity type (union field)
        @agent_messaged = data['agentMessaged']
        @user_messaged = data['userMessaged']
        @plan_generated = parse_plan_generated(data['planGenerated'])
        @plan_approved = data['planApproved']
        @progress_updated = data['progressUpdated']
        @session_completed = data['sessionCompleted']
        @session_failed = data['sessionFailed']
      end

      def type
        if agent_messaged
          :agent_messaged
        elsif user_messaged
          :user_messaged
        elsif plan_generated
          :plan_generated
        elsif plan_approved
          :plan_approved
        elsif progress_updated
          :progress_updated
        elsif session_completed
          :session_completed
        elsif session_failed
          :session_failed
        else
          :unknown
        end
      end

      # Type check helpers
      def agent_message?
        !agent_messaged.nil?
      end

      def user_message?
        !user_messaged.nil?
      end

      def plan_generated?
        !plan_generated.nil?
      end

      def plan_approved?
        !plan_approved.nil?
      end

      def progress_update?
        !progress_updated.nil?
      end

      def session_completed?
        !session_completed.nil?
      end

      def session_failed?
        !session_failed.nil?
      end

      def from_agent?
        originator == 'agent'
      end

      def from_user?
        originator == 'user'
      end

      def from_system?
        originator == 'system'
      end

      # Content helpers
      def message
        agent_messaged&.dig('agentMessage') || user_messaged&.dig('userMessage')
      end

      def plan
        plan_generated
      end

      def approved_plan_id
        plan_approved&.dig('planId')
      end

      def progress_title
        progress_updated&.dig('title')
      end

      def progress_description
        progress_updated&.dig('description')
      end

      def failure_reason
        session_failed&.dig('reason')
      end

      def to_h
        {
          name: name,
          id: id,
          description: description,
          create_time: create_time,
          originator: originator,
          type: type,
          artifacts: artifacts.map(&:to_h)
        }
      end

      private

      def parse_plan_generated(data)
        return nil unless data

        data['plan'] ? Plan.new(data['plan']) : nil
      end
    end
  end
end
