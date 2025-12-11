# frozen_string_literal: true

module JulesRuby
  module Models
    class Artifact
      attr_reader :change_set, :media, :bash_output

      def initialize(data)
        @change_set = data['changeSet']
        @media = data['media']
        @bash_output = data['bashOutput']
      end

      def type
        if change_set
          :change_set
        elsif media
          :media
        elsif bash_output
          :bash_output
        else
          :unknown
        end
      end

      # ChangeSet helpers
      def source
        change_set&.dig('source')
      end

      def git_patch
        change_set&.dig('gitPatch')
      end

      def unidiff_patch
        git_patch&.dig('unidiffPatch')
      end

      def base_commit_id
        git_patch&.dig('baseCommitId')
      end

      def suggested_commit_message
        git_patch&.dig('suggestedCommitMessage')
      end

      # Media helpers
      def media_data
        media&.dig('data')
      end

      def media_mime_type
        media&.dig('mimeType')
      end

      # BashOutput helpers
      def bash_command
        bash_output&.dig('command')
      end

      def bash_output_text
        bash_output&.dig('output')
      end

      def bash_exit_code
        bash_output&.dig('exitCode')
      end

      def to_h
        {
          change_set: change_set,
          media: media,
          bash_output: bash_output
        }
      end
    end
  end
end
