# frozen_string_literal: true

module JulesRuby
  module Models
    class Session
      # Session states
      STATES = %w[
        STATE_UNSPECIFIED
        QUEUED
        PLANNING
        AWAITING_PLAN_APPROVAL
        AWAITING_USER_FEEDBACK
        IN_PROGRESS
        PAUSED
        FAILED
        COMPLETED
      ].freeze

      # Automation modes
      AUTOMATION_MODES = %w[
        AUTOMATION_MODE_UNSPECIFIED
        AUTO_CREATE_PR
      ].freeze

      attr_reader :name, :id, :prompt, :title, :source_context, :state,
                  :url, :outputs, :create_time, :update_time,
                  :require_plan_approval, :automation_mode

      def initialize(data)
        @name = data['name']
        @id = data['id']
        @prompt = data['prompt']
        @title = data['title']
        @source_context = data['sourceContext'] ? SourceContext.new(data['sourceContext']) : nil
        @state = data['state']
        @url = data['url']
        @create_time = data['createTime']
        @update_time = data['updateTime']
        @require_plan_approval = data['requirePlanApproval']
        @automation_mode = data['automationMode']
        @outputs = parse_outputs(data['outputs'])
      end

      def to_h
        {
          name: name,
          id: id,
          prompt: prompt,
          title: title,
          source_context: source_context&.to_h,
          state: state,
          url: url,
          outputs: outputs.map(&:to_h),
          create_time: create_time,
          update_time: update_time
        }
      end

      # State check helpers
      def queued?
        state == 'QUEUED'
      end

      def planning?
        state == 'PLANNING'
      end

      def awaiting_plan_approval?
        state == 'AWAITING_PLAN_APPROVAL'
      end

      def awaiting_user_feedback?
        state == 'AWAITING_USER_FEEDBACK'
      end

      def in_progress?
        state == 'IN_PROGRESS'
      end

      def paused?
        state == 'PAUSED'
      end

      def failed?
        state == 'FAILED'
      end

      def completed?
        state == 'COMPLETED'
      end

      def active?
        %w[QUEUED PLANNING AWAITING_PLAN_APPROVAL AWAITING_USER_FEEDBACK IN_PROGRESS].include?(state)
      end

      private

      def parse_outputs(outputs_data)
        return [] unless outputs_data

        outputs_data.map do |output|
          if output['pullRequest']
            PullRequest.new(output['pullRequest'])
          else
            output
          end
        end
      end
    end
  end
end
