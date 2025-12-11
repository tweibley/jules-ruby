# frozen_string_literal: true

module JulesRuby
  module Resources
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end

      private

      def get(path, params: {})
        client.get(path, params: params)
      end

      def post(path, body: {})
        client.post(path, body: body)
      end

      def delete(path)
        client.delete(path)
      end
    end
  end
end
