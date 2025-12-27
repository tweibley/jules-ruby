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

    context 'with ConfigurationError' do
      let(:error) { JulesRuby::ConfigurationError.new('Original error message') }

      it 'outputs the error message and a hint' do
        # Expectation order matters or use allow/have_received
        allow(command).to receive(:warn)
        allow(command).to receive(:exit)

        command.call_error(error)

        expect(command).to have_received(:warn).with('Error: Original error message').ordered
        expect(command).to have_received(:warn).with('').ordered
        expect(command).to have_received(:warn).with('Hint: Set the JULES_API_KEY environment variable to fix this.').ordered
        expect(command).to have_received(:warn).with('  export JULES_API_KEY=your_api_key').ordered
      end
    end
  end
end
