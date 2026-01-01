# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli'

module JulesRuby
  module Commands
    # Subclass for testing protected methods
    class TestCommand < JulesRuby::Commands::Base
      def trigger_error(error)
        error_exit(error)
      end
    end
  end
end

RSpec.describe JulesRuby::Commands::Base do
  let(:command) { JulesRuby::Commands::TestCommand.new }

  describe '#error_exit' do
    context 'with ConfigurationError' do
      let(:error) { JulesRuby::ConfigurationError.new('API key missing') }

      it 'outputs error and hint in text mode' do
        output = capture_stderr do
          expect { command.trigger_error(error) }.to raise_error(SystemExit)
        end

        expect(output).to include('Error: API key missing')
        expect(output).to include('Tip: You can set the API key')
        expect(output).to include('export JULES_API_KEY=your_api_key')
        expect(output).to include('developers.google.com/jules/api')
      end

      it 'outputs only JSON error in json mode' do
        allow(command).to receive(:options).and_return({ format: 'json' })

        stdout = capture_stdout do
          expect { command.trigger_error(error) }.to raise_error(SystemExit)
        end

        json = JSON.parse(stdout)
        expect(json['error']).to eq('API key missing')
        expect(stdout).not_to include('Tip:')
      end
    end

    context 'with other errors' do
      let(:error) { StandardError.new('Something went wrong') }

      it 'outputs only the error message' do
        output = capture_stderr do
          expect { command.trigger_error(error) }.to raise_error(SystemExit)
        end

        expect(output).to include('Error: Something went wrong')
        expect(output).not_to include('Tip:')
      end
    end
  end

  def capture_stderr
    original = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
