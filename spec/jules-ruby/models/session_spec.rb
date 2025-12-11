# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Models::Session do
  let(:session_data) do
    {
      'name' => 'sessions/12345',
      'id' => '12345',
      'prompt' => 'Fix the bug',
      'title' => 'Bug Fix',
      'state' => 'IN_PROGRESS',
      'url' => 'https://jules.google.com/sessions/12345',
      'createTime' => '2025-01-01T00:00:00Z',
      'sourceContext' => {
        'source' => 'sources/github/owner/repo',
        'githubRepoContext' => { 'startingBranch' => 'main' }
      },
      'outputs' => [
        { 'pullRequest' => { 'url' => 'https://github.com/owner/repo/pull/1', 'title' => 'Fix', 'description' => 'Bug fix' } }
      ]
    }
  end

  subject(:session) { described_class.new(session_data) }

  describe 'attributes' do
    it 'parses basic attributes' do
      expect(session.name).to eq('sessions/12345')
      expect(session.id).to eq('12345')
      expect(session.prompt).to eq('Fix the bug')
      expect(session.title).to eq('Bug Fix')
      expect(session.state).to eq('IN_PROGRESS')
    end

    it 'parses source_context' do
      expect(session.source_context).to be_a(JulesRuby::Models::SourceContext)
      expect(session.source_context.source).to eq('sources/github/owner/repo')
    end

    it 'parses outputs with pull requests' do
      expect(session.outputs.first).to be_a(JulesRuby::Models::PullRequest)
      expect(session.outputs.first.url).to eq('https://github.com/owner/repo/pull/1')
    end
  end

  describe 'state helpers' do
    it 'responds to in_progress?' do
      expect(session.in_progress?).to be true
      expect(session.completed?).to be false
    end

    it 'responds to active?' do
      expect(session.active?).to be true
    end
  end
end
