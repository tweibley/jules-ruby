# frozen_string_literal: true

module JulesRuby
  module Models
    class PlanStep
      attr_reader :id, :title, :description, :index

      def initialize(data)
        @id = data['id']
        @title = data['title']
        @description = data['description']
        @index = data['index']
      end

      def to_h
        {
          id: id,
          title: title,
          description: description,
          index: index
        }
      end
    end
  end
end
