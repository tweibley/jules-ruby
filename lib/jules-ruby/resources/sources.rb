# frozen_string_literal: true

module JulesRuby
  module Resources
    class Sources < Base
      # List all available sources (connected repositories)
      #
      # @param page_token [String, nil] Token for pagination
      # @param page_size [Integer, nil] Number of results per page
      # @return [Hash] Response with :sources array and :next_page_token
      def list(page_token: nil, page_size: nil)
        params = {
          pageToken: page_token,
          pageSize: page_size
        }.compact

        response = get('/sources', params: params)

        {
          sources: (response['sources'] || []).map { |s| Models::Source.new(s) },
          next_page_token: response['nextPageToken']
        }
      end

      # Get a specific source by name
      #
      # @param name [String] The full resource name (e.g., "sources/github/owner/repo")
      # @return [Models::Source] The source object
      def find(name)
        raise ArgumentError, 'Source name is required' if name.nil? || name.to_s.strip.empty?

        # Ensure the name has the correct format
        path = name.start_with?('/') ? name : "/#{name}"
        response = get(path)
        Models::Source.new(response)
      end

      # List all sources with automatic pagination
      #
      # @yield [Models::Source] Each source
      # @return [Enumerator] If no block given
      def each(&block)
        return enum_for(:each) unless block_given?

        page_token = nil
        loop do
          result = list(page_token: page_token)
          result[:sources].each(&block)

          page_token = result[:next_page_token]
          break if page_token.nil? || page_token.empty?
        end
      end

      # Get all sources as an array
      #
      # @return [Array<Models::Source>]
      def all
        each.to_a
      end
    end
  end
end
