# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Configuration do
  let(:config) { described_class.new }

  describe '#initialize' do
    it 'sets default values' do
      expect(config.base_url).to eq(JulesRuby::Configuration::DEFAULT_BASE_URL)
      expect(config.timeout).to eq(JulesRuby::Configuration::DEFAULT_TIMEOUT)
    end

    it 'loads api_key from environment variable' do
      allow(ENV).to receive(:fetch).with('JULES_API_KEY', nil).and_return('env_key')
      expect(described_class.new.api_key).to eq('env_key')
    end
  end

  describe '#valid?' do
    it 'returns true when api_key is present' do
      config.api_key = 'test_key'
      expect(config.valid?).to be true
    end

    it 'returns false when api_key is nil' do
      config.api_key = nil
      expect(config.valid?).to be false
    end

    it 'returns false when api_key is empty' do
      config.api_key = ''
      expect(config.valid?).to be false
    end
  end

  describe 'attribute accessors' do
    it 'allows setting api_key' do
      config.api_key = 'new_key'
      expect(config.api_key).to eq('new_key')
    end

    it 'allows setting base_url' do
      config.base_url = 'http://example.com'
      expect(config.base_url).to eq('http://example.com')
    end

    it 'allows setting timeout' do
      config.timeout = 60
      expect(config.timeout).to eq(60)
    end
  end
end
