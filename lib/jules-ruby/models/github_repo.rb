# frozen_string_literal: true

module JulesRuby
  module Models
    class GitHubRepo
      attr_reader :owner, :repo, :is_private, :default_branch, :branches

      def initialize(data)
        @owner = data['owner']
        @repo = data['repo']
        @is_private = data['isPrivate']
        @default_branch = data['defaultBranch'] ? GitHubBranch.new(data['defaultBranch']) : nil
        @branches = (data['branches'] || []).map { |b| GitHubBranch.new(b) }
      end

      def to_h
        {
          owner: owner,
          repo: repo,
          is_private: is_private,
          default_branch: default_branch&.to_h,
          branches: branches.map(&:to_h)
        }
      end

      def full_name
        "#{owner}/#{repo}"
      end
    end
  end
end
