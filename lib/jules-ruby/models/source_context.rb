# frozen_string_literal: true

module JulesRuby
  module Models
    class SourceContext
      attr_reader :source, :github_repo_context

      def initialize(data)
        @source = data['source']
        @github_repo_context = data['githubRepoContext']
      end

      def starting_branch
        github_repo_context&.dig('startingBranch')
      end

      def to_h
        {
          source: source,
          github_repo_context: github_repo_context
        }
      end

      # Build a SourceContext hash for API requests
      def self.build(source:, starting_branch:)
        {
          'source' => source,
          'githubRepoContext' => {
            'startingBranch' => starting_branch
          }
        }
      end
    end
  end
end
