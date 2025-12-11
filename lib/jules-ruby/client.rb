# frozen_string_literal: true

require 'async'
require 'async/http/internet'
require 'json'
require 'uri'

module JulesRuby
  class Client
    attr_reader :configuration

    def initialize(api_key: nil, base_url: nil, timeout: nil)
      @configuration = JulesRuby.configuration&.dup || Configuration.new

      @configuration.api_key = api_key if api_key
      @configuration.base_url = base_url if base_url
      @configuration.timeout = timeout if timeout

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
      # Ensure base_url ends without slash and path starts with slash
      base = configuration.base_url.chomp('/')
      path = "/#{path}" unless path.start_with?('/')

      uri = URI.parse("#{base}#{path}")
      uri.query = URI.encode_www_form(params.compact) unless params.empty?
      uri.to_s
    end

    def build_headers
      [
        ['X-Goog-Api-Key', configuration.api_key],
        ['Content-Type', 'application/json'],
        ['Accept', 'application/json']
      ]
    end

    def handle_response(response)
      body = response.read
      status = response.status

      case status
      when 200..299
        body.empty? ? {} : JSON.parse(body)
      when 400
        raise BadRequestError.new('Bad request', status_code: status, response: body)
      when 401
        raise AuthenticationError.new('Invalid API key', status_code: status, response: body)
      when 403
        raise ForbiddenError.new('Access forbidden', status_code: status, response: body)
      when 404
        raise NotFoundError.new('Resource not found', status_code: status, response: body)
      when 429
        raise RateLimitError.new('Rate limit exceeded', status_code: status, response: body)
      when 500..599
        raise ServerError.new('Server error', status_code: status, response: body)
      else
        raise Error.new("Unexpected response: #{status}", status_code: status, response: body)
      end
    end
  end
end
