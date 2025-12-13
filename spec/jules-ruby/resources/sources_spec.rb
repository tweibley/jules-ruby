# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Resources::Sources do
  let(:client) { instance_double(JulesRuby::Client) }
  subject(:sources) { described_class.new(client) }

  describe '#list' do
    it 'calls client.get and returns sources' do
      response = {
        'sources' => [{ 'name' => 'sources/1' }],
        'nextPageToken' => 'token'
      }
      expect(client).to receive(:get).with('/sources', params: {}).and_return(response)

      result = sources.list
      expect(result[:sources]).to be_an(Array)
      expect(result[:sources].first).to be_a(JulesRuby::Models::Source)
      expect(result[:next_page_token]).to eq('token')
    end
  end

  describe '#find' do
    it 'calls client.get with name' do
      response = { 'name' => 'sources/1' }
      expect(client).to receive(:get).with('/sources/1', params: {}).and_return(response)
      source = sources.find('sources/1')
      expect(source).to be_a(JulesRuby::Models::Source)
    end
  end

  describe '#each' do
    it 'iterates through pages' do
      page1 = { 'sources' => [{ 'name' => 'a' }], 'nextPageToken' => 't2' }
      page2 = { 'sources' => [{ 'name' => 'b' }], 'nextPageToken' => nil }

      expect(client).to receive(:get).with('/sources', params: {}).and_return(page1)
      expect(client).to receive(:get).with('/sources', params: { pageToken: 't2' }).and_return(page2)

      items = []
      sources.each { |s| items << s }
      expect(items.size).to eq(2)
    end
  end

  describe '#all' do
    it 'returns all sources' do
      response = { 'sources' => [{ 'name' => 'a' }] }
      expect(client).to receive(:get).with('/sources', params: {}).and_return(response)
      expect(sources.all.size).to eq(1)
    end
  end
end
