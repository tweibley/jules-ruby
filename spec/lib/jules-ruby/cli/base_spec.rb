# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/base'
require 'jules-ruby/errors'

# Test helper class defined outside RSpec block to avoid Lint/ConstantDefinitionInBlock
class TestBaseCommand < JulesRuby::Commands::Base
  no_commands do
    def call_truncate(str, len)
      truncate(str, len)
    end

    def call_error(err)
      error_exit(err)
    end
  end
end

RSpec.describe JulesRuby::Commands::Base do
  let(:command) { TestBaseCommand.new }

  describe '#truncate' do
    it 'returns empty string for nil' do
      expect(command.call_truncate(nil, 10)).to eq('')
    end

    it 'returns string if shorter than length' do
      expect(command.call_truncate('hello', 10)).to eq('hello')
    end

    it 'truncates string if longer than length' do
      expect(command.call_truncate('hello world', 8)).to eq('hello...')
    end
  end

  describe '#error_exit' do
    before do
      allow(command).to receive(:warn)
    end

    it 'warns and exits' do
      expect { command.call_error(StandardError.new('fail')) }.to raise_error(SystemExit)
      # Match both plain and colored output (Pastel might be disabled in test env)
      expect(command).to have_received(:warn).with(/Error:.*fail/)
    end

    it 'provides a hint for ConfigurationError' do
      error = JulesRuby::ConfigurationError.new('config fail')
      expect { command.call_error(error) }.to raise_error(SystemExit)
      expect(command).to have_received(:warn).with(/Error:.*config fail/)
      expect(command).to have_received(:warn).with(/Hint: Check your environment variables/)
    end

    it 'provides a hint for AuthenticationError' do
      error = JulesRuby::AuthenticationError.new('auth fail')
      expect { command.call_error(error) }.to raise_error(SystemExit)
      expect(command).to have_received(:warn).with(/Error:.*auth fail/)
      expect(command).to have_received(:warn).with(/Hint: Verify your API key is correct/)
    end

    it 'provides a hint for NotFoundError' do
      error = JulesRuby::NotFoundError.new('not found')
      expect { command.call_error(error) }.to raise_error(SystemExit)
      expect(command).to have_received(:warn).with(/Error:.*not found/)
      expect(command).to have_received(:warn).with(/Hint: The requested resource could not be found/)
    end

    it 'outputs JSON error if format is json' do
      allow(command).to receive(:options).and_return({ format: 'json' })
      allow($stdout).to receive(:puts)
      expect { command.call_error(StandardError.new('fail')) }.to raise_error(SystemExit)
      expect($stdout).to have_received(:puts).with(include('"error":"fail"'))
    end
  end
end
