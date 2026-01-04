# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Client do
  let(:client) { described_class.new }

  describe 'HTTP error handling' do
    it 'raises BadRequestError on 400' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .to_return(status: 400, body: '{"error": "bad request"}')

      expect { client.get('/sessions') }.to raise_error(JulesRuby::BadRequestError)
    end

    it 'raises AuthenticationError on 401' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .to_return(status: 401, body: '{"error": "unauthorized"}')

      expect { client.get('/sessions') }.to raise_error(JulesRuby::AuthenticationError)
    end

    it 'raises ForbiddenError on 403' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .to_return(status: 403, body: '{"error": "forbidden"}')

      expect { client.get('/sessions') }.to raise_error(JulesRuby::ForbiddenError)
    end

    it 'raises NotFoundError on 404' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/notfound')
        .to_return(status: 404, body: '{"error": "not found"}')

      expect { client.get('/sessions/notfound') }.to raise_error(JulesRuby::NotFoundError)
    end

    it 'raises RateLimitError on 429' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .to_return(status: 429, body: '{"error": "rate limited"}')

      expect { client.get('/sessions') }.to raise_error(JulesRuby::RateLimitError)
    end

    it 'raises ServerError on 500' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .to_return(status: 500, body: '{"error": "server error"}')

      expect { client.get('/sessions') }.to raise_error(JulesRuby::ServerError)
    end

    it 'raises ServerError on 503' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .to_return(status: 503, body: '{"error": "service unavailable"}')

      expect { client.get('/sessions') }.to raise_error(JulesRuby::ServerError)
    end

    it 'raises Error on unexpected status codes' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .to_return(status: 418, body: 'I am a teapot')

      expect { client.get('/sessions') }.to raise_error(JulesRuby::Error)
    end

    describe 'error message extraction' do
      it 'extracts message from nested error object' do
        stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
          .to_return(status: 400, body: '{"error": {"message": "specific error"}}')

        expect { client.get('/sessions') }.to raise_error(JulesRuby::BadRequestError, 'specific error')
      end

      it 'extracts message from top-level message field' do
        stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
          .to_return(status: 400, body: '{"message": "simple message"}')

        expect { client.get('/sessions') }.to raise_error(JulesRuby::BadRequestError, 'simple message')
      end

      it 'falls back to default when body is not a hash' do
        stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
          .to_return(status: 400, body: '["array"]')

        expect { client.get('/sessions') }.to raise_error(JulesRuby::BadRequestError, 'Bad request')
      end

      it 'falls back to default when no error message found in hash' do
        stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
          .to_return(status: 400, body: '{"other": "data"}')

        expect { client.get('/sessions') }.to raise_error(JulesRuby::BadRequestError, 'Bad request')
      end

      it 'falls back to default when JSON is invalid' do
        stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
          .to_return(status: 400, body: 'invalid-json')

        expect { client.get('/sessions') }.to raise_error(JulesRuby::BadRequestError, 'Bad request')
      end
    end
  end

  describe '#initialize' do
    it 'raises ConfigurationError if api_key is missing' do
      # Mock ENV.fetch to ensure no default is loaded
      allow(ENV).to receive(:fetch).with('JULES_API_KEY', nil).and_return(nil)
      # And ensure global config doesn't interfere
      allow(JulesRuby).to receive(:configuration).and_return(nil)

      expect { described_class.new(api_key: nil) }.to raise_error(JulesRuby::ConfigurationError)
    end
  end

  describe '#request' do
    it 'raises ArgumentError for unsupported methods' do
      # Stub build_headers to avoid other errors
      allow_any_instance_of(described_class).to receive(:build_headers).and_return({})
      # Force call request with unsupported method
      expect { client.send(:request, :patch, '/') }.to raise_error(ArgumentError, /Unsupported HTTP method/)
    end
  end

  describe '#build_headers' do
    # Protocol::HTTP::Headers accepts both Array of Arrays and Hash via .to_a conversion
    # This test documents the expected return type for the optimization in this method
    it 'returns a Hash compatible with Protocol::HTTP::Headers' do
      headers = client.send(:build_headers)

      expect(headers).to be_a(Hash)
      expect(headers['X-Goog-Api-Key']).to eq(client.configuration.api_key)
      expect(headers['Content-Type']).to eq('application/json')
      expect(headers['Accept']).to eq('application/json')
    end

    it 'returns a new Hash instance each time (not the frozen constant)' do
      headers1 = client.send(:build_headers)
      headers2 = client.send(:build_headers)

      expect(headers1).not_to be(headers2)
      expect(headers1).not_to be_frozen
    end
  end

  # Resource accessors
  describe '#post' do
    before do
      stub_request(:post, 'https://jules.googleapis.com/v1alpha/sessions')
        .to_return(status: 200, body: '{"name": "sessions/123"}', headers: { 'Content-Type' => 'application/json' })
    end

    it 'makes POST requests' do
      result = client.post('/sessions', body: { prompt: 'test' })
      expect(result['name']).to eq('sessions/123')
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, 'https://jules.googleapis.com/v1alpha/sessions/123')
        .to_return(status: 204, body: nil)
    end

    it 'makes DELETE requests' do
      result = client.delete('/sessions/123')
      expect(result).to eq({})
    end
  end

  describe 'URL building' do
    it 'handles paths without leading slash' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .to_return(status: 200, body: '{}')

      result = client.get('sessions')
      expect(result).to eq({})
    end

    it 'handles query params' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .with(query: { pageSize: 10 })
        .to_return(status: 200, body: '{}')

      result = client.get('/sessions', params: { pageSize: 10 })
      expect(result).to eq({})
    end

    it 'replaces existing query params in path with new params' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .with(query: { pageSize: 10 })
        .to_return(status: 200, body: '{}')

      result = client.get('/sessions?old=1', params: { pageSize: 10 })
      expect(result).to eq({})
    end

    it 'preserves fragments when adding params' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .with(query: { pageSize: 10 })
        .to_return(status: 200, body: '{}')

      # Async::HTTP::Internet#get might strip fragment before sending, but build_url should include it
      # We check build_url directly here
      url = client.send(:build_url, '/sessions#top', { pageSize: 10 })
      expect(url).to eq('https://jules.googleapis.com/v1alpha/sessions?pageSize=10#top')
    end

    it 'preserves fragments when replacing query params' do
      url = client.send(:build_url, '/sessions?old=1#top', { pageSize: 10 })
      expect(url).to eq('https://jules.googleapis.com/v1alpha/sessions?pageSize=10#top')
    end
  end

  describe 'configuration overrides' do
    it 'allows overriding base_url' do
      custom_client = described_class.new(base_url: 'https://custom.example.com/v1')

      stub_request(:get, 'https://custom.example.com/v1/sessions')
        .to_return(status: 200, body: '{}')

      result = custom_client.get('/sessions')
      expect(result).to eq({})
    end

    it 'allows overriding timeout' do
      custom_client = described_class.new(timeout: 120)
      expect(custom_client.configuration.timeout).to eq(120)
    end
  end
end

RSpec.describe JulesRuby::Error do
  it 'stores response and status_code' do
    error = JulesRuby::Error.new('test', response: 'body', status_code: 500)
    expect(error.message).to eq('test')
    expect(error.response).to eq('body')
    expect(error.status_code).to eq(500)
  end
end

RSpec.describe JulesRuby::Configuration do
  describe '#valid?' do
    it 'returns true when api_key is present' do
      config = JulesRuby::Configuration.new
      config.api_key = 'test'
      expect(config.valid?).to be true
    end

    it 'returns false when api_key is nil' do
      JulesRuby.reset_configuration!
      config = JulesRuby::Configuration.new
      config.api_key = nil
      expect(config.valid?).to be false
    end

    it 'returns false when api_key is empty' do
      config = JulesRuby::Configuration.new
      config.api_key = ''
      expect(config.valid?).to be false
    end
  end
end

RSpec.describe JulesRuby do
  describe '.configure' do
    it 'returns configuration without block' do
      config = JulesRuby.configure
      expect(config).to be_a(JulesRuby::Configuration)
    end

    it 'yields configuration with block' do
      JulesRuby.configure do |c|
        c.timeout = 999
      end
      expect(JulesRuby.configuration.timeout).to eq(999)
    end
  end

  describe '.reset_configuration!' do
    it 'resets configuration to defaults' do
      JulesRuby.configure { |c| c.timeout = 999 }
      JulesRuby.reset_configuration!
      expect(JulesRuby.configuration.timeout).to eq(30)
    end
  end
end
