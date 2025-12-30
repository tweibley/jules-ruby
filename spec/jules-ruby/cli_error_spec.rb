# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/base'
require 'jules-ruby/errors'

RSpec.describe JulesRuby::Commands::Base do
  # Create a test command class to access protected methods
  let(:command_class) do
    Class.new(described_class) do
      def test_error_exit(error)
        error_exit(error)
      end
    end
  end

  let(:command) { command_class.new }

  describe '#error_exit' do
    let(:error_message) { 'Something went wrong' }
    let(:error) { StandardError.new(error_message) }

    before do
      # Mock exit to avoid stopping the test
      allow(command).to receive(:exit).and_return(nil)
    end

    context 'when format is table (default)' do
      before do
        allow(command).to receive(:options).and_return({ format: 'table' })
        # Allow Thor to treat output as a TTY to enable colors
        allow($stdout).to receive(:tty?).and_return(true)
        allow($stderr).to receive(:tty?).and_return(true)
      end

      it 'outputs colored error message' do
        expect(command).to receive(:warn).with(/Error:/) do |msg|
          # Check for ANSI red color code (Thor uses \e[31m)
          expect(msg).to include("\e[31mError:\e[0m")
          expect(msg).to include(error_message)
        end
        command.test_error_exit(error)
      end

      context 'with ConfigurationError' do
        let(:error) { JulesRuby::ConfigurationError.new(error_message) }

        it 'outputs helpful hints' do
          # Expect the main error message
          expect(command).to receive(:warn).with(/Error:/)

          # Expect the hints
          expect(command).to receive(:warn).with(/Tip: Set JULES_API_KEY/)
          expect(command).to receive(:warn).with(%r{See https://developers.google.com/jules/api})

          command.test_error_exit(error)
        end
      end
    end

    context 'when format is json' do
      before do
        allow(command).to receive(:options).and_return({ format: 'json' })
      end

      it 'outputs pure JSON without colors' do
        expect(command).to receive(:puts).with('{"error":"Something went wrong"}')
        # Should not call warn
        expect(command).not_to receive(:warn)

        command.test_error_exit(error)
      end
    end
  end
end
