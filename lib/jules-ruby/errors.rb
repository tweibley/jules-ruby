# frozen_string_literal: true

module JulesRuby
  # Base error class
  class Error < StandardError
    attr_reader :response, :status_code

    def initialize(message = nil, response: nil, status_code: nil)
      @response = response
      @status_code = status_code
      super(message)
    end
  end

  # 400 Bad Request
  class BadRequestError < Error; end

  # 401 Unauthorized
  class AuthenticationError < Error; end

  # 403 Forbidden
  class ForbiddenError < Error; end

  # 404 Not Found
  class NotFoundError < Error; end

  # 429 Too Many Requests
  class RateLimitError < Error; end

  # 5xx Server Errors
  class ServerError < Error; end

  # Configuration error
  class ConfigurationError < Error; end
end
