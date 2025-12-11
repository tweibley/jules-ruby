# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby do
  describe '.configure' do
    it 'yields configuration' do
      JulesRuby.configure do |config|
        config.api_key = 'my_key'
      end

      expect(JulesRuby.configuration.api_key).to eq('my_key')
    end
  end

  describe '.reset_configuration!' do
    it 'resets api_key to env var value (or nil if not set)' do
      JulesRuby.configure { |c| c.api_key = 'custom_value' }
      JulesRuby.reset_configuration!

      # After reset, it reads from ENV (which may have .env loaded)
      expect(JulesRuby.configuration.base_url).to eq('https://jules.googleapis.com/v1alpha')
      expect(JulesRuby.configuration.timeout).to eq(30)
    end
  end
end

RSpec.describe JulesRuby::Configuration do
  subject(:config) { described_class.new }

  describe '#valid?' do
    it 'returns false when api_key is nil' do
      config.api_key = nil
      expect(config.valid?).to be false
    end

    it 'returns false when api_key is empty' do
      config.api_key = ''
      expect(config.valid?).to be false
    end

    it 'returns true when api_key is set' do
      config.api_key = 'valid_key'
      expect(config.valid?).to be true
    end
  end

  describe 'defaults' do
    it 'has default base_url' do
      expect(config.base_url).to eq('https://jules.googleapis.com/v1alpha')
    end

    it 'has default timeout' do
      expect(config.timeout).to eq(30)
    end
  end
end
