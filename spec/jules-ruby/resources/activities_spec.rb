# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Resources::Activities do
  let(:client) { instance_double(JulesRuby::Client) }
  subject(:activities) { described_class.new(client) }

  describe '#list' do
    it 'calls client.get and returns activities' do
      response = {
        'activities' => [{ 'type' => 'message' }],
        'nextPageToken' => 'token'
      }
      expect(client).to receive(:get).with('/sessions/123/activities', params: {}).and_return(response)

      result = activities.list('123')
      expect(result[:activities]).to be_an(Array)
      expect(result[:activities].first).to be_a(JulesRuby::Models::Activity)
      expect(result[:next_page_token]).to eq('token')
    end

    it 'normalizes session name' do
      response = { 'activities' => [] }
      expect(client).to receive(:get).with('/sessions/123/activities', params: {}).and_return(response)
      activities.list('sessions/123')
    end
  end

  describe '#find' do
    it 'calls client.get with name' do
      response = { 'type' => 'message' }
      expect(client).to receive(:get).with('/sessions/123/activities/abc', params: {}).and_return(response)
      activity = activities.find('sessions/123/activities/abc')
      expect(activity).to be_a(JulesRuby::Models::Activity)
    end
  end

  describe '#each' do
    it 'iterates through pages' do
      page1 = { 'activities' => [{ 'type' => 'a' }], 'nextPageToken' => 't2' }
      page2 = { 'activities' => [{ 'type' => 'b' }], 'nextPageToken' => nil }

      expect(client).to receive(:get).with('/sessions/123/activities', params: {}).and_return(page1)
      expect(client).to receive(:get).with('/sessions/123/activities', params: { pageToken: 't2' }).and_return(page2)

      items = []
      activities.each('123') { |a| items << a }
      expect(items.size).to eq(2)
    end
  end

  describe '#all' do
    it 'returns all activities' do
      response = { 'activities' => [{ 'type' => 'a' }] }
      expect(client).to receive(:get).with('/sessions/123/activities', params: {}).and_return(response)
      expect(activities.all('123').size).to eq(1)
    end
  end
end
