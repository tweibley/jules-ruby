# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/banner'

RSpec.describe JulesRuby::Banner do
  describe '.hsl_to_rgb' do
    it 'converts red (0, 100, 50) correctly' do
      expect(described_class.hsl_to_rgb(0, 100, 50)).to eq([255, 0, 0])
    end

    it 'converts green (120, 100, 50) correctly' do
      expect(described_class.hsl_to_rgb(120, 100, 50)).to eq([0, 255, 0])
    end

    it 'converts blue (240, 100, 50) correctly' do
      expect(described_class.hsl_to_rgb(240, 100, 50)).to eq([0, 0, 255])
    end

    it 'converts white (0, 0, 100) correctly' do
      expect(described_class.hsl_to_rgb(0, 0, 100)).to eq([255, 255, 255])
    end

    it 'converts black (0, 0, 0) correctly' do
      expect(described_class.hsl_to_rgb(0, 0, 0)).to eq([0, 0, 0])
    end

    it 'handles hue ranges correctly' do
      # Yellow
      expect(described_class.hsl_to_rgb(60, 100, 50)).to eq([255, 255, 0])
      # Cyan
      expect(described_class.hsl_to_rgb(180, 100, 50)).to eq([0, 255, 255])
      # Magenta
      expect(described_class.hsl_to_rgb(300, 100, 50)).to eq([255, 0, 255])
    end
  end

  describe '.print_banner' do
    it 'outputs the banner with ANSI codes' do
      expect { described_class.print_banner }.to output(/\[38;2;\d+;\d+;\d+m/).to_stdout
    end

    it 'outputs the octopus and jules text' do
      expect { described_class.print_banner }.to output.to_stdout
    end
  end
end
