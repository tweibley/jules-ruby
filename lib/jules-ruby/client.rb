# frozen_string_literal: true

require 'async'
require 'async/http/internet'
require 'json'
require 'uri'

module JulesRuby
  class Client
    attr_reader :configuration

    DEFAULT_HEADERS = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }.freeze

    ERROR_MAPPING = {
      400 => [BadRequestError, 'Bad request'],
      401 => [AuthenticationError, 'Invalid API key'],
      403 => [ForbiddenError, 'Access forbidden'],
      404 => [NotFoundError, 'Resource not found'],
      429 => [RateLimitError, 'Rate limit exceeded']
    }.freeze

    def initialize(api_key: nil, base_url: nil, timeout: nil)
      @configuration = JulesRuby.configuration&.dup || Configuration.new

      @configuration.api_key = api_key if api_key
      @configuration.base_url = base_url if base_url
      @configuration.timeout = timeout if timeout

      @base_url_string = @configuration.base_url.chomp('/')

      validate_configuration!
    end

    # Resource accessors
    def sources
      @sources ||= Resources::Sources.new(self)
    end

    def sessions
      @sessions ||= Resources::Sessions.new(self)
    end

    def activities
      @activities ||= Resources::Activities.new(self)
    end

    # HTTP methods
    def get(path, params: {})
      request(:get, path, params: params)
    end

    def post(path, body: {})
      request(:post, path, body: body)
    end

    def delete(path)
      request(:delete, path)
    end

    private

    def validate_configuration!
      return if configuration.valid?

      raise ConfigurationError,
            'API key is required. Set JULES_API_KEY environment variable or pass api_key to Client.new'
    end

    def request(method, path, params: {}, body: nil)
      url = build_url(path, params)

      Async do
        internet = Async::HTTP::Internet.new

        begin
          headers = build_headers

          response = case method
                     when :get
                       internet.get(url, headers)
                     when :post
                       internet.post(url, headers, body ? JSON.generate(body) : nil)
                     when :delete
                       internet.delete(url, headers)
                     else
                       raise ArgumentError, "Unsupported HTTP method: #{method}"
                     end

          handle_response(response)
        ensure
          internet.close
        end
      end.wait
    end

    def build_url(path, params)
      path = "/#{path}" unless path.start_with?('/')

      # Optimization: Avoid URI.parse and string allocations for base URL
      url = "#{@base_url_string}#{path}"

      unless params.empty?
        compact_params = params.compact
        unless compact_params.empty?
          query = URI.encode_www_form(compact_params)
          url = "#{url}?#{query}"
        end
      end

      url
    end

    def build_headers
      # Optimization: Reuse DEFAULT_HEADERS hash to avoid multiple array allocations per request
      headers = DEFAULT_HEADERS.dup
      headers['X-Goog-Api-Key'] = configuration.api_key
      headers
    end

    def handle_response(response)
      body = response.read
      status = response.status

      return parse_success_response(body) if (200..299).cover?(status)

      handle_error_response(status, body)
    end

    def parse_success_response(body)
      body.nil? || body.empty? ? {} : JSON.parse(body)
    end

    def handle_error_response(status, body)
      if (klass, default_msg = ERROR_MAPPING[status])
        raise klass.new(extract_error_message(body, default_msg), status_code: status, response: body)
      end

      if (500..599).cover?(status)
        raise ServerError.new(extract_error_message(body, 'Server error'), status_code: status, response: body)
      end

      raise Error.new("Unexpected response: #{status}", status_code: status, response: body)
    end

    def extract_error_message(body, default)
      return default if body.nil? || body.empty?

      data = JSON.parse(body)
      return default unless data.is_a?(Hash)

      if data['error'].is_a?(Hash)
        data.dig('error', 'message') || default
      elsif data['error'].is_a?(String)
        data['error']
      elsif data['message'].is_a?(String)
        data['message']
      else
        default
      end
    rescue JSON::ParserError
      default
    end
  end
end
