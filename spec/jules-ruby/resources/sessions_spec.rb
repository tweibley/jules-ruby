# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Resources::Sessions do
  let(:client) { instance_double(JulesRuby::Client) }
  subject(:sessions) { described_class.new(client) }

  describe '#list' do
    it 'calls client.get and returns sessions' do
      response = {
        'sessions' => [{ 'id' => '1', 'name' => 'sessions/1' }],
        'nextPageToken' => 'next_token'
      }
      expect(client).to receive(:get).with('/sessions', params: { pageToken: 'token' }).and_return(response)

      result = sessions.list(page_token: 'token')
      expect(result[:sessions]).to be_an(Array)
      expect(result[:sessions].first).to be_a(JulesRuby::Models::Session)
      expect(result[:next_page_token]).to eq('next_token')
    end

    it 'handles empty response' do
      expect(client).to receive(:get).with('/sessions', params: {}).and_return({})
      result = sessions.list
      expect(result[:sessions]).to eq([])
      expect(result[:next_page_token]).to be_nil
    end
  end

  describe '#find' do
    let(:session_data) { { 'id' => '123', 'name' => 'sessions/123' } }

    it 'calls client.get with full name' do
      expect(client).to receive(:get).with('/sessions/123', params: {}).and_return(session_data)
      session = sessions.find('sessions/123')
      expect(session).to be_a(JulesRuby::Models::Session)
      expect(session.id).to eq('123')
    end

    it 'calls client.get with id only' do
      expect(client).to receive(:get).with('/sessions/123', params: {}).and_return(session_data)
      sessions.find('123')
    end

    it 'calls client.get with leading slash' do
      expect(client).to receive(:get).with('/sessions/123', params: {}).and_return(session_data)
      sessions.find('/sessions/123')
    end
  end

  describe '#create' do
    let(:session_data) { { 'id' => '123' } }
    let(:source_context) { { 'source' => 'repo' } }

    it 'calls client.post with required params' do
      expected_body = {
        'prompt' => 'hello',
        'sourceContext' => source_context
      }
      expect(client).to receive(:post).with('/sessions', body: expected_body).and_return(session_data)

      session = sessions.create(prompt: 'hello', source_context: source_context)
      expect(session).to be_a(JulesRuby::Models::Session)
    end

    it 'calls client.post with optional params' do
      expected_body = {
        'prompt' => 'hello',
        'sourceContext' => source_context,
        'title' => 'My Session',
        'requirePlanApproval' => true,
        'automationMode' => 'AUTO'
      }
      expect(client).to receive(:post).with('/sessions', body: expected_body).and_return(session_data)

      sessions.create(
        prompt: 'hello',
        source_context: source_context,
        title: 'My Session',
        require_plan_approval: true,
        automation_mode: 'AUTO'
      )
    end
  end

  describe '#approve_plan' do
    it 'calls client.post to approve plan' do
      expect(client).to receive(:post).with('/sessions/123:approvePlan', body: {}).and_return({ 'id' => '123' })
      session = sessions.approve_plan('123')
      expect(session).to be_a(JulesRuby::Models::Session)
    end
  end

  describe '#send_message' do
    it 'calls client.post to send message' do
      expect(client).to receive(:post).with('/sessions/123:sendMessage', body: { 'prompt' => 'hi' }).and_return({ 'id' => '123' })
      session = sessions.send_message('123', prompt: 'hi')
      expect(session).to be_a(JulesRuby::Models::Session)
    end
  end

  describe '#destroy' do
    it 'calls client.delete' do
      expect(client).to receive(:delete).with('/sessions/123')
      sessions.destroy('123')
    end
  end

  describe '#each' do
    it 'iterates through all pages' do
      page1 = { 'sessions' => [{ 'id' => '1' }], 'nextPageToken' => 'token2' }
      page2 = { 'sessions' => [{ 'id' => '2' }], 'nextPageToken' => nil }

      expect(client).to receive(:get).with('/sessions', params: {}).and_return(page1)
      expect(client).to receive(:get).with('/sessions', params: { pageToken: 'token2' }).and_return(page2)

      items = []
      sessions.each { |s| items << s }
      expect(items.size).to eq(2)
      expect(items[0].id).to eq('1')
      expect(items[1].id).to eq('2')
    end
  end

  describe '#all' do
    it 'returns array of all sessions' do
      page1 = { 'sessions' => [{ 'id' => '1' }], 'nextPageToken' => nil }
      expect(client).to receive(:get).with('/sessions', params: {}).and_return(page1)

      all = sessions.all
      expect(all).to be_an(Array)
      expect(all.size).to eq(1)
    end
  end
end
