# frozen_string_literal: true

module JulesRuby
  module Resources
    class Activities < Base
      # List activities for a session
      #
      # @param session_name [String] The session name (e.g., "sessions/123") or just the ID
      # @param page_token [String, nil] Token for pagination
      # @param page_size [Integer, nil] Number of results per page
      # @return [Hash] Response with :activities array and :next_page_token
      def list(session_name, page_token: nil, page_size: nil)
        path = "#{normalize_session_path(session_name)}/activities"
        params = {
          pageToken: page_token,
          pageSize: page_size
        }.compact

        response = get(path, params: params)

        {
          activities: (response['activities'] || []).map { |a| Models::Activity.new(a) },
          next_page_token: response['nextPageToken']
        }
      end

      # Get a specific activity by name
      #
      # @param name [String] The full activity name (e.g., "sessions/123/activities/abc")
      # @return [Models::Activity] The activity object
      def find(name)
        path = name.start_with?('/') ? name : "/#{name}"
        response = get(path)
        Models::Activity.new(response)
      end

      # List all activities for a session with automatic pagination
      #
      # @param session_name [String] The session name or ID
      # @yield [Models::Activity] Each activity
      # @return [Enumerator] If no block given
      def each(session_name, &block)
        return enum_for(:each, session_name) unless block_given?

        page_token = nil
        loop do
          result = list(session_name, page_token: page_token)
          result[:activities].each(&block)

          page_token = result[:next_page_token]
          break if page_token.nil? || page_token.empty?
        end
      end

      # Get all activities for a session as an array
      #
      # @param session_name [String] The session name or ID
      # @return [Array<Models::Activity>]
      def all(session_name)
        each(session_name).to_a
      end

      private

      def normalize_session_path(name)
        if name.start_with?('sessions/')
          "/#{name}"
        elsif name.start_with?('/sessions/')
          name
        else
          "/sessions/#{name}"
        end
      end
    end
  end
end
