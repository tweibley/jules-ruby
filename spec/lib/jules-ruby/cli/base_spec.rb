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
    context 'with generic error' do
      it 'warns and exits' do
        allow(command).to receive(:warn)
        expect { command.call_error(StandardError.new('fail')) }.to raise_error(SystemExit)
        expect(command).to have_received(:warn).with('Error: fail')
      end

      it 'outputs JSON error if format is json' do
        allow(command).to receive(:options).and_return({ format: 'json' })
        allow($stdout).to receive(:puts)
        expect { command.call_error(StandardError.new('fail')) }.to raise_error(SystemExit)
        expect($stdout).to have_received(:puts).with(include('"error":"fail"'))
      end
    end

    context 'with ConfigurationError' do
      let(:config_error) { JulesRuby::ConfigurationError.new('API key is required') }

      it 'provides helpful hint in text mode' do
        allow(command).to receive(:warn)

        expect { command.call_error(config_error) }.to raise_error(SystemExit)

        expect(command).to have_received(:warn).with('Error: API key is required')
        expect(command).to have_received(:warn).with(include('HINT: Export JULES_API_KEY'))
        expect(command).to have_received(:warn).with(include('https://developers.google.com/jules/api'))
      end

      it 'does not provide hint in JSON mode' do
        allow(command).to receive(:options).and_return({ format: 'json' })
        allow($stdout).to receive(:puts) # capturing stdout
        allow(command).to receive(:warn)

        expect { command.call_error(config_error) }.to raise_error(SystemExit)

        expect($stdout).to have_received(:puts).with(include('"error":"API key is required"'))
        expect(command).not_to have_received(:warn).with(include('HINT'))
      end
    end
  end
end
