# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Models::SourceContext do
  describe '#initialize' do
    it 'initializes from hash data' do
      data = { 'source' => 'foo', 'githubRepoContext' => { 'startingBranch' => 'main' } }
      context = described_class.new(data)
      expect(context.source).to eq('foo')
      expect(context.github_repo_context).to eq({ 'startingBranch' => 'main' })
    end
  end

  describe '#starting_branch' do
    it 'returns branch from context' do
      context = described_class.new('githubRepoContext' => { 'startingBranch' => 'dev' })
      expect(context.starting_branch).to eq('dev')
    end

    it 'returns nil if context is missing' do
      context = described_class.new({})
      expect(context.starting_branch).to be_nil
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      context = described_class.new({ 'source' => 's', 'githubRepoContext' => nil })
      expect(context.to_h).to eq({ source: 's', github_repo_context: nil })
    end
  end

  describe '.build' do
    it 'builds API compatible hash' do
      hash = described_class.build(source: 'src', starting_branch: 'feat')
      expect(hash).to eq({
                           'source' => 'src',
                           'githubRepoContext' => { 'startingBranch' => 'feat' }
                         })
    end
  end
end
