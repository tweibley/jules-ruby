# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Client do
  let(:client) { described_class.new(api_key: 'test_key') }

  describe 'security' do
    context 'when configured with insecure HTTP base_url' do
      it 'raises ConfigurationError for remote hosts' do
        expect do
          described_class.new(base_url: 'http://api.example.com')
        end.to raise_error(JulesRuby::ConfigurationError, /HTTPS is required for remote hosts/)
      end

      it 'allows HTTP for localhost' do
        expect do
          described_class.new(base_url: 'http://localhost:3000')
        end.not_to raise_error
      end

      it 'allows HTTP for 127.0.0.1' do
        expect do
          described_class.new(base_url: 'http://127.0.0.1:3000')
        end.not_to raise_error
      end

      it 'allows HTTP for ::1' do
        expect do
          described_class.new(base_url: 'http://[::1]:3000')
        end.not_to raise_error
      end
    end

    context 'when configured with secure HTTPS base_url' do
      it 'allows HTTPS for remote hosts' do
        expect do
          described_class.new(base_url: 'https://api.example.com')
        end.not_to raise_error
      end
    end

    context 'when configured with invalid base_url' do
      it 'raises ConfigurationError for invalid URIs' do
        expect do
          described_class.new(base_url: '::not_a_uri::')
        end.to raise_error(JulesRuby::ConfigurationError, /Invalid base_url/)
      end
    end
  end
end
