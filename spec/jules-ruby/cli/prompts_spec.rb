# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/prompts'

RSpec.describe JulesRuby::Prompts do
  describe '.rgb_color' do
    let(:text) { 'Hello World' }
    let(:color) { :purple }
    let(:r) { 147 }
    let(:g) { 112 }
    let(:b) { 219 }

    it 'wraps text in ANSI escape codes' do
      result = described_class.rgb_color(text, color)
      expect(result).to eq("\e[38;2;#{r};#{g};#{b}m#{text}\e[0m")
    end

    context 'with text containing ANSI codes' do
      let(:malicious_text) { "\e[31mMalicious\e[0m Content" }

      it 'strips existing ANSI codes before wrapping' do
        result = described_class.rgb_color(malicious_text, color)
        # Expect "Malicious Content" to be wrapped in purple, without the red color codes
        expect(result).to eq("\e[38;2;#{r};#{g};#{b}mMalicious Content\e[0m")
      end
    end

    context 'with nil text' do
      it 'handles nil gracefully' do
        expect { described_class.rgb_color(nil, color) }.not_to raise_error
        result = described_class.rgb_color(nil, color)
        expect(result).to eq("\e[38;2;#{r};#{g};#{b}m\e[0m")
      end
    end
  end
end
