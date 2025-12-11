# frozen_string_literal: true

module JulesRuby
  class Configuration
    attr_accessor :api_key, :base_url, :timeout

    DEFAULT_BASE_URL = 'https://jules.googleapis.com/v1alpha'
    DEFAULT_TIMEOUT = 30

    def initialize
      @api_key = ENV.fetch('JULES_API_KEY', nil)
      @base_url = DEFAULT_BASE_URL
      @timeout = DEFAULT_TIMEOUT
    end

    def valid?
      !api_key.nil? && !api_key.empty?
    end
  end
end
