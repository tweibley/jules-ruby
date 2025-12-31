# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Client do
  let(:api_key) { 'test_api_key' }

  describe 'HTTPS Enforcement' do
    it 'raises ConfigurationError when base_url is insecure (http)' do
      expect do
        described_class.new(api_key: api_key, base_url: 'http://api.example.com')
      end.to raise_error(JulesRuby::ConfigurationError, /HTTPS is required/)
    end

    it 'allows https base_url' do
      expect do
        described_class.new(api_key: api_key, base_url: 'https://api.example.com')
      end.not_to raise_error
    end

    it 'allows http for localhost' do
      expect do
        described_class.new(api_key: api_key, base_url: 'http://localhost:8080')
      end.not_to raise_error
    end

    it 'allows http for 127.0.0.1' do
      expect do
        described_class.new(api_key: api_key, base_url: 'http://127.0.0.1:8080')
      end.not_to raise_error
    end

    it 'allows http for IPv6 loopback' do
      expect do
        described_class.new(api_key: api_key, base_url: 'http://[::1]:8080')
      end.not_to raise_error
    end
  end
end
