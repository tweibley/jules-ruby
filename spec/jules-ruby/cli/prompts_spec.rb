# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/prompts'

RSpec.describe JulesRuby::Prompts do
  describe '.rgb_color' do
    it 'wraps text in ANSI color codes' do
      result = described_class.rgb_color('hello', :purple)
      expect(result).to include('hello')
      # Purple color code: \e[38;2;147;112;219m
      expect(result).to start_with("\e[38;2;147;112;219m")
      expect(result).to end_with("\e[0m")
    end

    it 'strips existing ANSI codes to prevent injection and coloring issues' do
      input = "hello \e[31mred\e[0m world"
      result = described_class.rgb_color(input, :purple)

      # The internal ANSI codes should be gone
      expect(result).not_to include("\e[31m")

      # The text content should remain
      expect(result).to include('hello red world')

      # The wrapper color should still be there
      expect(result).to start_with("\e[38;2;147;112;219m")
    end
  end
end
