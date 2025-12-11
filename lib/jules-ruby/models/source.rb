# frozen_string_literal: true

module JulesRuby
  module Models
    class Source
      attr_reader :name, :id, :github_repo

      def initialize(data)
        @name = data['name']
        @id = data['id']
        @github_repo = data['githubRepo'] ? GitHubRepo.new(data['githubRepo']) : nil
      end

      def to_h
        {
          name: name,
          id: id,
          github_repo: github_repo&.to_h
        }
      end
    end
  end
end
