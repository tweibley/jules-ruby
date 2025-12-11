# frozen_string_literal: true

module JulesRuby
  module Models
    class PullRequest
      attr_reader :url, :title, :description

      def initialize(data)
        @url = data['url']
        @title = data['title']
        @description = data['description']
      end

      def to_h
        {
          url: url,
          title: title,
          description: description
        }
      end
    end
  end
end
