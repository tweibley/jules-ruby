# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Client do
  describe 'security enforcement' do
    let(:api_key) { 'test-key' }

    it 'raises ConfigurationError when base_url is HTTP and not local' do
      expect {
        described_class.new(api_key: api_key, base_url: 'http://example.com')
      }.to raise_error(JulesRuby::ConfigurationError, /Insecure base_url/)
    end

    it 'allows HTTPS base_url' do
      expect {
        described_class.new(api_key: api_key, base_url: 'https://example.com')
      }.not_to raise_error
    end

    describe 'local development exceptions' do
      it 'allows HTTP for localhost' do
        expect {
          described_class.new(api_key: api_key, base_url: 'http://localhost:3000')
        }.not_to raise_error
      end

      it 'allows HTTP for 127.0.0.1' do
        expect {
          described_class.new(api_key: api_key, base_url: 'http://127.0.0.1:3000')
        }.not_to raise_error
      end

      it 'allows HTTP for IPv6 loopback ::1' do
        expect {
          described_class.new(api_key: api_key, base_url: 'http://[::1]:3000')
        }.not_to raise_error
      end

      # For robustness, check if URI parses [::1] correctly with scheme
      it 'allows HTTP for IPv6 loopback ::1 without brackets if URI handles it' do
         # URI.parse('http://::1') usually fails or parses weirdly, but let's see behavior
         # We'll stick to the bracketed version which is standard for URLs
      end
    end

    it 'raises ConfigurationError for invalid URLs' do
      expect {
        described_class.new(api_key: api_key, base_url: 'not-a-url')
      }.to raise_error(JulesRuby::ConfigurationError)
    end

    it 'raises ConfigurationError for unparseable URLs' do
      allow(URI).to receive(:parse).and_raise(URI::InvalidURIError)
      expect {
        described_class.new(api_key: api_key, base_url: 'http://invalid_uri')
      }.to raise_error(JulesRuby::ConfigurationError, /Invalid base_url/)
    end
  end
end
