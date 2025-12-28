# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Client do
  describe 'security enforcement' do
    context 'when base_url uses http' do
      it 'raises ConfigurationError for non-localhost hosts' do
        expect {
          described_class.new(base_url: 'http://api.example.com')
        }.to raise_error(JulesRuby::ConfigurationError, /HTTPS is required/i)
      end

      it 'allows http for localhost' do
        expect {
          described_class.new(base_url: 'http://localhost:3000')
        }.not_to raise_error
      end

      it 'allows http for 127.0.0.1' do
        expect {
          described_class.new(base_url: 'http://127.0.0.1:3000')
        }.not_to raise_error
      end

      it 'allows http for [::1]' do
        expect {
          described_class.new(base_url: 'http://[::1]:3000')
        }.not_to raise_error
      end
    end

    context 'when base_url uses https' do
      it 'does not raise error' do
        expect {
          described_class.new(base_url: 'https://api.example.com')
        }.not_to raise_error
      end
    end

    context 'when base_url is invalid' do
      it 'raises ConfigurationError for missing scheme' do
        expect {
          described_class.new(base_url: 'api.example.com')
        }.to raise_error(JulesRuby::ConfigurationError)
      end
    end
  end
end
