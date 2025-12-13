# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Models::GitHubRepo do
  let(:data) do
    {
      'owner' => 'me',
      'repo' => 'project',
      'isPrivate' => true,
      'defaultBranch' => { 'displayName' => 'main' },
      'branches' => [{ 'displayName' => 'dev' }]
    }
  end
  subject(:repo) { described_class.new(data) }

  it 'parses attributes' do
    expect(repo.owner).to eq('me')
    expect(repo.repo).to eq('project')
    expect(repo.is_private).to be true
    expect(repo.default_branch).to be_a(JulesRuby::Models::GitHubBranch)
    expect(repo.default_branch.display_name).to eq('main')
    expect(repo.branches.size).to eq(1)
    expect(repo.branches.first.display_name).to eq('dev')
  end

  it 'returns full name' do
    expect(repo.full_name).to eq('me/project')
  end

  it 'handles missing default branch' do
    data['defaultBranch'] = nil
    expect(described_class.new(data).default_branch).to be_nil
  end

  describe '#to_h' do
    it 'returns hash' do
      expect(repo.to_h[:owner]).to eq('me')
      expect(repo.to_h[:default_branch]).to be_a(Hash)
      expect(repo.to_h[:branches]).to be_a(Array)
    end
  end
end
