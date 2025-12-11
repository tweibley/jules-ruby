# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Client do
  let(:client) { described_class.new }

  describe '#initialize' do
    it 'uses global configuration by default' do
      JulesRuby.configure { |c| c.api_key = 'global_key' }
      client = described_class.new
      expect(client.configuration.api_key).to eq('global_key')
    end

    it 'allows overriding api_key' do
      client = described_class.new(api_key: 'override_key')
      expect(client.configuration.api_key).to eq('override_key')
    end

    it 'raises ConfigurationError when api_key is missing' do
      JulesRuby.reset_configuration!
      JulesRuby.configuration.api_key = nil
      expect { described_class.new }.to raise_error(JulesRuby::ConfigurationError)
    end
  end

  describe 'resource accessors' do
    it 'provides sources resource' do
      expect(client.sources).to be_a(JulesRuby::Resources::Sources)
    end

    it 'provides sessions resource' do
      expect(client.sessions).to be_a(JulesRuby::Resources::Sessions)
    end

    it 'provides activities resource' do
      expect(client.activities).to be_a(JulesRuby::Resources::Activities)
    end

    it 'memoizes resource instances' do
      expect(client.sources).to be(client.sources)
    end
  end
end
