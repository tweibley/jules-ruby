# frozen_string_literal: true

module JulesRuby
  module Resources
    class Sessions < Base
      # List all sessions
      #
      # @param page_token [String, nil] Token for pagination
      # @param page_size [Integer, nil] Number of results per page
      # @return [Hash] Response with :sessions array and :next_page_token
      def list(page_token: nil, page_size: nil)
        params = {
          pageToken: page_token,
          pageSize: page_size
        }.compact

        response = get('/sessions', params: params)

        {
          sessions: (response['sessions'] || []).map { |s| Models::Session.new(s) },
          next_page_token: response['nextPageToken']
        }
      end

      # Get a specific session by name or ID
      #
      # @param name [String] The session name (e.g., "sessions/123") or just the ID
      # @return [Models::Session] The session object
      def find(name)
        path = normalize_session_path(name)
        response = get(path)
        Models::Session.new(response)
      end

      # Create a new session
      #
      # @param prompt [String] The prompt to start the session with
      # @param source_context [Hash] The source context (use SourceContext.build helper)
      # @param title [String, nil] Optional title for the session
      # @param require_plan_approval [Boolean, nil] If true, plans require explicit approval
      # @param automation_mode [String, nil] e.g., "AUTO_CREATE_PR"
      # @return [Models::Session] The created session
      def create(prompt:, source_context:, title: nil, require_plan_approval: nil, automation_mode: nil)
        body = {
          'prompt' => prompt,
          'sourceContext' => source_context
        }

        body['title'] = title if title
        body['requirePlanApproval'] = require_plan_approval unless require_plan_approval.nil?
        body['automationMode'] = automation_mode if automation_mode

        response = post('/sessions', body: body)
        Models::Session.new(response)
      end

      # Approve the current plan for a session
      #
      # @param session_name [String] The session name (e.g., "sessions/123") or just the ID
      # @return [Models::Session] The updated session
      def approve_plan(session_name)
        path = "#{normalize_session_path(session_name)}:approvePlan"
        response = post(path, body: {})
        Models::Session.new(response)
      end

      # Send a message to a session
      #
      # @param session_name [String] The session name (e.g., "sessions/123") or just the ID
      # @param prompt [String] The message to send
      # @return [Models::Session] The updated session
      def send_message(session_name, prompt:)
        path = "#{normalize_session_path(session_name)}:sendMessage"
        response = post(path, body: { 'prompt' => prompt })
        Models::Session.new(response)
      end

      # Delete a session
      #
      # @param session_name [String] The session name (e.g., "sessions/123") or just the ID
      # @return [void]
      def destroy(session_name)
        path = normalize_session_path(session_name)
        delete(path)
        nil
      end

      # List all sessions with automatic pagination
      #
      # @yield [Models::Session] Each session
      # @return [Enumerator] If no block given
      def each(&block)
        return enum_for(:each) unless block_given?

        page_token = nil
        loop do
          result = list(page_token: page_token)
          result[:sessions].each(&block)

          page_token = result[:next_page_token]
          break if page_token.nil? || page_token.empty?
        end
      end

      # Get all sessions as an array
      #
      # @return [Array<Models::Session>]
      def all
        each.to_a
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
