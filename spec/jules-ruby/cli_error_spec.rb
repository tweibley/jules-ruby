# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli'

RSpec.describe JulesRuby::CLI do
  describe 'ConfigurationError handling' do
    # Helper to capture stderr
    def capture_stderr
      original = $stderr
      $stderr = StringIO.new
      yield
      $stderr.string
    ensure
      $stderr = original
    end

    # Helper to capture stdout
    def capture_stdout
      original = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = original
    end

    before do
      # Mock the client to raise ConfigurationError
      allow(JulesRuby::Client).to receive(:new).and_raise(
        JulesRuby::ConfigurationError,
        'API key is required. Set JULES_API_KEY environment variable or pass api_key to Client.new'
      )
    end

    it 'displays a helpful hint when ConfigurationError occurs in table format' do
      output = capture_stderr do
        expect do
          JulesRuby::CLI.start(%w[sessions list])
        end.to raise_error(SystemExit)
      end

      expect(output).to include('Error: API key is required')
      expect(output).to include('Get your API key at: https://developers.google.com/jules/api')
    end

    it 'does NOT display the hint when format is JSON' do
      output = capture_stdout do
        expect do
          JulesRuby::CLI.start(['sessions', 'list', '--format=json'])
        end.to raise_error(SystemExit)
      end

      parsed = JSON.parse(output)
      expect(parsed).to have_key('error')
      expect(parsed['error']).to include('API key is required')

      # JSON output should only contain the JSON object, no extra text
      expect(output).not_to include('Get your API key at')
    end
  end
end
