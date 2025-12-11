# frozen_string_literal: true

module JulesRuby
  module Models
    class Plan
      attr_reader :id, :steps, :create_time

      def initialize(data)
        @id = data['id']
        @steps = (data['steps'] || []).map { |s| PlanStep.new(s) }
        @create_time = data['createTime']
      end

      def to_h
        {
          id: id,
          steps: steps.map(&:to_h),
          create_time: create_time
        }
      end
    end
  end
end
