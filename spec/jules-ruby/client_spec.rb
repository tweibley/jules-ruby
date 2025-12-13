# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Client do
  let(:client) { described_class.new }

  describe '#initialize' do
    it 'uses global configuration by default' do
      JulesRuby.configure { |c| c.api_key = 'global_key' }
      client = described_class.new
      expect(client.configuration.api_key).to eq('global_key')
    end

    it 'allows overriding api_key' do
      client = described_class.new(api_key: 'override_key')
      expect(client.configuration.api_key).to eq('override_key')
    end

    it 'raises ConfigurationError when api_key is missing' do
      JulesRuby.reset_configuration!
      JulesRuby.configuration.api_key = nil
      expect { described_class.new }.to raise_error(JulesRuby::ConfigurationError)
    end
  end

  describe 'resource accessors' do
    it 'provides sources resource' do
      expect(client.sources).to be_a(JulesRuby::Resources::Sources)
    end

    it 'provides sessions resource' do
      expect(client.sessions).to be_a(JulesRuby::Resources::Sessions)
    end

    it 'provides activities resource' do
      expect(client.activities).to be_a(JulesRuby::Resources::Activities)
    end

    it 'memoizes resource instances' do
      expect(client.sources).to be(client.sources)
    end
  end

  describe 'HTTP requests' do
    let(:base_url) { 'https://jules.googleapis.com/v1alpha' }

    before do
      JulesRuby.configure { |c| c.api_key = 'test_key' }
    end

    describe '#get' do
      it 'performs GET request' do
        stub_request(:get, "#{base_url}/path")
          .with(headers: { 'X-Goog-Api-Key' => 'test_key' })
          .to_return(body: '{"data":1}', headers: { 'Content-Type' => 'application/json' })

        expect(client.get('/path')).to eq({ 'data' => 1 })
      end

      it 'merges params' do
        stub_request(:get, "#{base_url}/path?q=1")
          .to_return(body: '{}')

        client.get('/path', params: { q: 1 })
      end
    end

    describe '#post' do
      it 'performs POST request' do
        stub_request(:post, "#{base_url}/path")
          .with(body: '{"data":1}')
          .to_return(body: '{"result":true}', headers: { 'Content-Type' => 'application/json' })

        expect(client.post('/path', body: { data: 1 })).to eq({ 'result' => true })
      end
    end

    describe '#delete' do
      it 'performs DELETE request' do
        stub_request(:delete, "#{base_url}/path")
          .to_return(status: 204, body: "")

        expect(client.delete('/path')).to eq({})
      end
    end

    describe 'error handling' do
      it 'raises BadRequestError on 400' do
        stub_request(:get, "#{base_url}/err").to_return(status: 400)
        expect { client.get('/err') }.to raise_error(JulesRuby::BadRequestError)
      end

      it 'raises AuthenticationError on 401' do
        stub_request(:get, "#{base_url}/err").to_return(status: 401)
        expect { client.get('/err') }.to raise_error(JulesRuby::AuthenticationError)
      end

      it 'raises ForbiddenError on 403' do
        stub_request(:get, "#{base_url}/err").to_return(status: 403)
        expect { client.get('/err') }.to raise_error(JulesRuby::ForbiddenError)
      end

      it 'raises NotFoundError on 404' do
        stub_request(:get, "#{base_url}/err").to_return(status: 404)
        expect { client.get('/err') }.to raise_error(JulesRuby::NotFoundError)
      end

      it 'raises RateLimitError on 429' do
        stub_request(:get, "#{base_url}/err").to_return(status: 429)
        expect { client.get('/err') }.to raise_error(JulesRuby::RateLimitError)
      end

      it 'raises ServerError on 500' do
        stub_request(:get, "#{base_url}/err").to_return(status: 500)
        expect { client.get('/err') }.to raise_error(JulesRuby::ServerError)
      end

      it 'raises generic Error on unknown status' do
        stub_request(:get, "#{base_url}/err").to_return(status: 418)
        expect { client.get('/err') }.to raise_error(JulesRuby::Error)
      end
    end
  end
end
