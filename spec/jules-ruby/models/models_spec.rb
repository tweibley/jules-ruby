# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Models::Artifact do
  describe 'change_set artifact' do
    let(:artifact_data) do
      {
        'changeSet' => {
          'source' => 'sources/github/owner/repo',
          'gitPatch' => {
            'unidiffPatch' => '--- a/file\n+++ b/file\n@@ -1 +1 @@\n-old\n+new',
            'baseCommitId' => 'abc123',
            'suggestedCommitMessage' => 'Fix bug'
          }
        }
      }
    end

    subject(:artifact) { described_class.new(artifact_data) }

    it 'identifies type as change_set' do
      expect(artifact.type).to eq(:change_set)
    end

    it 'provides change_set helpers' do
      expect(artifact.source).to eq('sources/github/owner/repo')
      expect(artifact.base_commit_id).to eq('abc123')
      expect(artifact.suggested_commit_message).to eq('Fix bug')
      expect(artifact.unidiff_patch).to include('old')
    end

    it 'converts to hash' do
      hash = artifact.to_h
      expect(hash[:change_set]).not_to be_nil
    end
  end

  describe 'media artifact' do
    let(:artifact_data) do
      {
        'media' => {
          'data' => 'base64data',
          'mimeType' => 'image/png'
        }
      }
    end

    subject(:artifact) { described_class.new(artifact_data) }

    it 'identifies type as media' do
      expect(artifact.type).to eq(:media)
    end

    it 'provides media helpers' do
      expect(artifact.media_data).to eq('base64data')
      expect(artifact.media_mime_type).to eq('image/png')
    end
  end

  describe 'bash_output artifact' do
    let(:artifact_data) do
      {
        'bashOutput' => {
          'command' => 'rspec',
          'output' => '10 examples, 0 failures',
          'exitCode' => 0
        }
      }
    end

    subject(:artifact) { described_class.new(artifact_data) }

    it 'identifies type as bash_output' do
      expect(artifact.type).to eq(:bash_output)
    end

    it 'provides bash helpers' do
      expect(artifact.bash_command).to eq('rspec')
      expect(artifact.bash_output_text).to eq('10 examples, 0 failures')
      expect(artifact.bash_exit_code).to eq(0)
    end
  end

  describe 'unknown artifact' do
    subject(:artifact) { described_class.new({}) }

    it 'identifies type as unknown' do
      expect(artifact.type).to eq(:unknown)
    end
  end
end

RSpec.describe JulesRuby::Models::Session do
  describe 'state helpers' do
    it 'identifies queued state' do
      session = described_class.new('state' => 'QUEUED')
      expect(session.queued?).to be true
      expect(session.active?).to be true
    end

    it 'identifies planning state' do
      session = described_class.new('state' => 'PLANNING')
      expect(session.planning?).to be true
      expect(session.active?).to be true
    end

    it 'identifies awaiting_plan_approval state' do
      session = described_class.new('state' => 'AWAITING_PLAN_APPROVAL')
      expect(session.awaiting_plan_approval?).to be true
      expect(session.active?).to be true
    end

    it 'identifies awaiting_user_feedback state' do
      session = described_class.new('state' => 'AWAITING_USER_FEEDBACK')
      expect(session.awaiting_user_feedback?).to be true
      expect(session.active?).to be true
    end

    it 'identifies in_progress state' do
      session = described_class.new('state' => 'IN_PROGRESS')
      expect(session.in_progress?).to be true
      expect(session.active?).to be true
    end

    it 'identifies paused state' do
      session = described_class.new('state' => 'PAUSED')
      expect(session.paused?).to be true
      expect(session.active?).to be false
    end

    it 'identifies failed state' do
      session = described_class.new('state' => 'FAILED')
      expect(session.failed?).to be true
      expect(session.active?).to be false
    end

    it 'identifies completed state' do
      session = described_class.new('state' => 'COMPLETED')
      expect(session.completed?).to be true
      expect(session.active?).to be false
    end
  end

  describe 'with outputs' do
    let(:session_data) do
      {
        'name' => 'sessions/123',
        'outputs' => [
          { 'pullRequest' => { 'url' => 'https://github.com/pr/1' } },
          { 'someOther' => 'data' }
        ]
      }
    end

    subject(:session) { described_class.new(session_data) }

    it 'parses pull request outputs' do
      expect(session.outputs.first).to be_a(JulesRuby::Models::PullRequest)
    end

    it 'keeps unknown outputs as-is' do
      expect(session.outputs.last).to be_a(Hash)
    end

    it 'converts to hash' do
      hash = session.to_h
      expect(hash[:outputs]).to be_an(Array)
    end
  end

  describe 'with source_context' do
    let(:session_data) do
      {
        'name' => 'sessions/123',
        'sourceContext' => {
          'source' => 'sources/github/owner/repo'
        }
      }
    end

    subject(:session) { described_class.new(session_data) }

    it 'parses source context' do
      expect(session.source_context).to be_a(JulesRuby::Models::SourceContext)
    end
  end
end

RSpec.describe JulesRuby::Models::Source do
  describe 'with github_repo' do
    let(:source_data) do
      {
        'name' => 'sources/github/owner/repo',
        'id' => 'github/owner/repo',
        'githubRepo' => {
          'owner' => 'owner',
          'repo' => 'repo',
          'isPrivate' => false
        }
      }
    end

    subject(:source) { described_class.new(source_data) }

    it 'parses github repo' do
      expect(source.github_repo).to be_a(JulesRuby::Models::GitHubRepo)
      expect(source.github_repo.full_name).to eq('owner/repo')
    end

    it 'converts to hash' do
      hash = source.to_h
      expect(hash[:github_repo]).not_to be_nil
    end
  end

  describe 'without github_repo' do
    subject(:source) { described_class.new('name' => 'test') }

    it 'handles missing github_repo' do
      expect(source.github_repo).to be_nil
      expect(source.to_h[:github_repo]).to be_nil
    end
  end
end

RSpec.describe JulesRuby::Models::GitHubRepo do
  let(:repo_data) do
    {
      'owner' => 'myorg',
      'repo' => 'myrepo',
      'isPrivate' => true,
      'defaultBranch' => { 'displayName' => 'main' },
      'branches' => [
        { 'displayName' => 'main' },
        { 'displayName' => 'develop' }
      ]
    }
  end

  subject(:repo) { described_class.new(repo_data) }

  it 'parses basic attributes' do
    expect(repo.owner).to eq('myorg')
    expect(repo.repo).to eq('myrepo')
    expect(repo.is_private).to be true
  end

  it 'provides full_name' do
    expect(repo.full_name).to eq('myorg/myrepo')
  end

  it 'parses default branch' do
    expect(repo.default_branch).to be_a(JulesRuby::Models::GitHubBranch)
    expect(repo.default_branch.display_name).to eq('main')
  end

  it 'parses branches' do
    expect(repo.branches.length).to eq(2)
    expect(repo.branches.first).to be_a(JulesRuby::Models::GitHubBranch)
  end

  it 'converts to hash' do
    hash = repo.to_h
    expect(hash[:is_private]).to be true
  end
end

RSpec.describe JulesRuby::Models::Plan do
  let(:plan_data) do
    {
      'id' => 'plan123',
      'steps' => [
        { 'id' => 's1', 'title' => 'Step 1', 'index' => 0 },
        { 'id' => 's2', 'title' => 'Step 2', 'index' => 1 }
      ]
    }
  end

  subject(:plan) { described_class.new(plan_data) }

  it 'parses attributes' do
    expect(plan.id).to eq('plan123')
  end

  it 'parses steps' do
    expect(plan.steps.length).to eq(2)
    expect(plan.steps.first).to be_a(JulesRuby::Models::PlanStep)
  end

  it 'converts to hash' do
    hash = plan.to_h
    expect(hash[:steps].first).to be_a(Hash)
  end
end

RSpec.describe JulesRuby::Models::PlanStep do
  let(:step_data) do
    {
      'id' => 'step1',
      'title' => 'Setup environment',
      'index' => 0,
      'description' => 'Install dependencies'
    }
  end

  subject(:step) { described_class.new(step_data) }

  it 'parses attributes' do
    expect(step.id).to eq('step1')
    expect(step.title).to eq('Setup environment')
    expect(step.index).to eq(0)
    expect(step.description).to eq('Install dependencies')
  end

  it 'converts to hash' do
    hash = step.to_h
    expect(hash[:title]).to eq('Setup environment')
  end
end

RSpec.describe JulesRuby::Models::SourceContext do
  let(:context_data) do
    {
      'source' => 'sources/github/owner/repo',
      'githubRepoContext' => {
        'startingBranch' => 'develop'
      }
    }
  end

  subject(:context) { described_class.new(context_data) }

  it 'parses attributes' do
    expect(context.source).to eq('sources/github/owner/repo')
    expect(context.github_repo_context).not_to be_nil
    expect(context.starting_branch).to eq('develop')
  end

  it 'converts to hash' do
    hash = context.to_h
    expect(hash[:source]).to eq('sources/github/owner/repo')
  end
end

RSpec.describe JulesRuby::Models::PullRequest do
  let(:pr_data) do
    {
      'url' => 'https://github.com/owner/repo/pull/123',
      'title' => 'Fix bug',
      'description' => 'This fixes the bug'
    }
  end

  subject(:pr) { described_class.new(pr_data) }

  it 'parses attributes' do
    expect(pr.url).to eq('https://github.com/owner/repo/pull/123')
    expect(pr.title).to eq('Fix bug')
    expect(pr.description).to eq('This fixes the bug')
  end

  it 'converts to hash' do
    hash = pr.to_h
    expect(hash[:url]).to eq('https://github.com/owner/repo/pull/123')
  end
end
