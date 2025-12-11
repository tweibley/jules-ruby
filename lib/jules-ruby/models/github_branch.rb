# frozen_string_literal: true

module JulesRuby
  module Models
    class GitHubBranch
      attr_reader :display_name

      def initialize(data)
        @display_name = data['displayName']
      end

      def to_h
        { display_name: display_name }
      end
    end
  end
end
