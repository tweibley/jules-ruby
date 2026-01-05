# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Client do
  describe '#validate_configuration!' do
    let(:api_key) { 'test-key' }

    it 'raises ConfigurationError for insecure base_url' do
      expect do
        JulesRuby::Client.new(api_key: api_key, base_url: 'http://example.com')
      end.to raise_error(JulesRuby::ConfigurationError, /HTTPS required/)
    end

    it 'allows http for localhost' do
      expect do
        JulesRuby::Client.new(api_key: api_key, base_url: 'http://localhost:3000')
      end.not_to raise_error
    end

    it 'allows http for 127.0.0.1' do
      expect do
        JulesRuby::Client.new(api_key: api_key, base_url: 'http://127.0.0.1:3000')
      end.not_to raise_error
    end

    it 'allows https for example.com' do
      expect do
        JulesRuby::Client.new(api_key: api_key, base_url: 'https://example.com')
      end.not_to raise_error
    end

    it 'raises ConfigurationError for malformed http url without host' do
      expect do
        # "http:path" parses with nil host in some URI versions, or simply insecure scheme
        JulesRuby::Client.new(api_key: api_key, base_url: 'http:path')
      end.to raise_error(JulesRuby::ConfigurationError)
    end
  end
end
