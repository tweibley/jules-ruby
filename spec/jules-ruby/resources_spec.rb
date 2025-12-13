# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Resources::Sessions do
  let(:client) { JulesRuby::Client.new }
  let(:sessions) { client.sessions }

  describe '#list' do
    before do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .with(query: { pageSize: 10 })
        .to_return(
          status: 200,
          body: {
            'sessions' => [{ 'name' => 'sessions/123', 'state' => 'ACTIVE' }],
            'nextPageToken' => 'token123'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'lists sessions with pagination params' do
      result = sessions.list(page_size: 10)
      expect(result[:sessions].first.name).to eq('sessions/123')
      expect(result[:next_page_token]).to eq('token123')
    end
  end

  describe '#find' do
    before do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123')
        .to_return(
          status: 200,
          body: { 'name' => 'sessions/abc123', 'state' => 'ACTIVE' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'finds session by ID' do
      session = sessions.find('abc123')
      expect(session.name).to eq('sessions/abc123')
    end

    it 'finds session by full name' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/full123')
        .to_return(
          status: 200,
          body: { 'name' => 'sessions/full123' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      session = sessions.find('sessions/full123')
      expect(session.name).to eq('sessions/full123')
    end

    it 'finds session with leading slash' do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/slash123')
        .to_return(
          status: 200,
          body: { 'name' => 'sessions/slash123' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      session = sessions.find('/sessions/slash123')
      expect(session.name).to eq('sessions/slash123')
    end
  end

  describe '#create' do
    before do
      stub_request(:post, 'https://jules.googleapis.com/v1alpha/sessions')
        .to_return(
          status: 200,
          body: { 'name' => 'sessions/new123', 'state' => 'QUEUED' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'creates a session with required params' do
      session = sessions.create(
        prompt: 'Fix the bug',
        source_context: { 'source' => 'sources/github/owner/repo' }
      )
      expect(session.name).to eq('sessions/new123')
    end

    it 'creates a session with all params' do
      session = sessions.create(
        prompt: 'Fix the bug',
        source_context: { 'source' => 'sources/github/owner/repo' },
        title: 'Bug Fix',
        require_plan_approval: true,
        automation_mode: 'AUTO_CREATE_PR'
      )
      expect(session.queued?).to be true
    end
  end

  describe '#approve_plan' do
    before do
      stub_request(:post, 'https://jules.googleapis.com/v1alpha/sessions/abc123:approvePlan')
        .to_return(
          status: 200,
          body: { 'name' => 'sessions/abc123', 'state' => 'IN_PROGRESS' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'approves a plan' do
      session = sessions.approve_plan('abc123')
      expect(session.active?).to be true
    end
  end

  describe '#send_message' do
    before do
      stub_request(:post, 'https://jules.googleapis.com/v1alpha/sessions/abc123:sendMessage')
        .to_return(
          status: 200,
          body: { 'name' => 'sessions/abc123' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a message' do
      session = sessions.send_message('abc123', prompt: 'Add tests')
      expect(session.name).to eq('sessions/abc123')
    end
  end

  describe '#destroy' do
    before do
      stub_request(:delete, 'https://jules.googleapis.com/v1alpha/sessions/abc123')
        .to_return(status: 200, body: '', headers: {})
    end

    it 'deletes a session' do
      result = sessions.destroy('abc123')
      expect(result).to be_nil
    end
  end

  describe '#each and #all' do
    before do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .to_return(
          status: 200,
          body: {
            'sessions' => [{ 'name' => 'sessions/1' }],
            'nextPageToken' => 'page2'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
        .with(query: { pageToken: 'page2' })
        .to_return(
          status: 200,
          body: { 'sessions' => [{ 'name' => 'sessions/2' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'iterates through all pages' do
      names = sessions.all.map(&:name)
      expect(names).to eq(%w[sessions/1 sessions/2])
    end

    it 'returns enumerator when no block given' do
      expect(sessions.each).to be_an(Enumerator)
    end
  end
end

RSpec.describe JulesRuby::Resources::Sources do
  let(:client) { JulesRuby::Client.new }
  let(:sources) { client.sources }

  describe '#list' do
    before do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sources')
        .to_return(
          status: 200,
          body: { 'sources' => [{ 'name' => 'sources/github/o/r' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'lists sources' do
      result = sources.list
      expect(result[:sources].first.name).to eq('sources/github/o/r')
    end
  end

  describe '#find' do
    before do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sources/github/owner/repo')
        .to_return(
          status: 200,
          body: { 'name' => 'sources/github/owner/repo' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'finds source without leading slash' do
      source = sources.find('sources/github/owner/repo')
      expect(source.name).to eq('sources/github/owner/repo')
    end

    it 'finds source with leading slash' do
      source = sources.find('/sources/github/owner/repo')
      expect(source.name).to eq('sources/github/owner/repo')
    end
  end

  describe '#each and #all' do
    before do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sources')
        .to_return(
          status: 200,
          body: {
            'sources' => [{ 'name' => 'sources/1' }],
            'nextPageToken' => 'page2'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sources')
        .with(query: { pageToken: 'page2' })
        .to_return(
          status: 200,
          body: { 'sources' => [{ 'name' => 'sources/2' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'paginates through all sources' do
      all_sources = sources.all
      expect(all_sources.map(&:name)).to eq(%w[sources/1 sources/2])
    end

    it 'returns enumerator when no block given' do
      expect(sources.each).to be_an(Enumerator)
    end
  end
end

RSpec.describe JulesRuby::Resources::Activities do
  let(:client) { JulesRuby::Client.new }
  let(:activities) { client.activities }

  describe '#list' do
    before do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc/activities')
        .to_return(
          status: 200,
          body: { 'activities' => [{ 'name' => 'sessions/abc/activities/1' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'lists activities for session ID' do
      result = activities.list('abc')
      expect(result[:activities].first.name).to eq('sessions/abc/activities/1')
    end
  end

  describe '#find' do
    before do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc/activities/xyz')
        .to_return(
          status: 200,
          body: { 'name' => 'sessions/abc/activities/xyz' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'finds activity by name' do
      activity = activities.find('sessions/abc/activities/xyz')
      expect(activity.name).to eq('sessions/abc/activities/xyz')
    end

    it 'finds activity with leading slash' do
      activity = activities.find('/sessions/abc/activities/xyz')
      expect(activity.name).to eq('sessions/abc/activities/xyz')
    end
  end

  describe '#each and #all' do
    before do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc/activities')
        .to_return(
          status: 200,
          body: {
            'activities' => [{ 'name' => 'act/1' }],
            'nextPageToken' => 'page2'
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc/activities')
        .with(query: { pageToken: 'page2' })
        .to_return(
          status: 200,
          body: { 'activities' => [{ 'name' => 'act/2' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'paginates through all activities' do
      all_activities = activities.all('abc')
      expect(all_activities.map(&:name)).to eq(%w[act/1 act/2])
    end

    it 'returns enumerator when no block given' do
      expect(activities.each('abc')).to be_an(Enumerator)
    end
  end

  describe 'path normalization' do
    before do
      stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/full/activities')
        .to_return(
          status: 200,
          body: { 'activities' => [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'handles session with sessions/ prefix' do
      result = activities.list('sessions/full')
      expect(result[:activities]).to eq([])
    end

    it 'handles session with leading slash' do
      result = activities.list('/sessions/full')
      expect(result[:activities]).to eq([])
    end
  end
end
