# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/prompts'

RSpec.describe JulesRuby::Prompts do
  describe '.rgb_color' do
    it 'colors text with the specified color' do
      text = 'Hello'
      # Purple is [147, 112, 219]
      expected = "\e[38;2;147;112;219mHello\e[0m"
      expect(described_class.rgb_color(text, :purple)).to eq(expected)
    end

    it 'sanitizes input text by stripping existing ANSI codes' do
      text = "Hello \e[31mRed\e[0m World"
      # Purple is [147, 112, 219]
      # The sanitization should remove \e[31m and \e[0m inside the string
      expected = "\e[38;2;147;112;219mHello Red World\e[0m"
      expect(described_class.rgb_color(text, :purple)).to eq(expected)
    end
  end
end
