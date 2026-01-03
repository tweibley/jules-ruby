# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Client do
  let(:api_key) { 'test_api_key' }

  describe 'security' do
    context 'when base_url is insecure (http)' do
      it 'raises ConfigurationError for non-local host' do
        expect do
          described_class.new(api_key: api_key, base_url: 'http://example.com')
        end.to raise_error(JulesRuby::ConfigurationError, /HTTPS is required for remote base_url/)
      end

      it 'allows http for localhost' do
        expect do
          described_class.new(api_key: api_key, base_url: 'http://localhost:3000')
        end.not_to raise_error
      end

      it 'allows http for 127.0.0.1' do
        expect do
          described_class.new(api_key: api_key, base_url: 'http://127.0.0.1:3000')
        end.not_to raise_error
      end

      it 'allows http for [::1]' do
        expect do
          described_class.new(api_key: api_key, base_url: 'http://[::1]:3000')
        end.not_to raise_error
      end
    end

    context 'when base_url is secure (https)' do
      it 'allows https for remote host' do
        expect do
          described_class.new(api_key: api_key, base_url: 'https://example.com')
        end.not_to raise_error
      end
    end
  end
end
