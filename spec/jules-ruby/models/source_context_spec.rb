# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Models::SourceContext do
  let(:data) do
    {
      'source' => 'src',
      'githubRepoContext' => { 'startingBranch' => 'main' }
    }
  end
  subject(:ctx) { described_class.new(data) }

  it 'parses attributes' do
    expect(ctx.source).to eq('src')
    expect(ctx.starting_branch).to eq('main')
  end

  it 'to_h' do
    expect(ctx.to_h[:source]).to eq('src')
  end

  describe '.build' do
    it 'builds correct hash' do
      hash = described_class.build(source: 's', starting_branch: 'b')
      expect(hash['source']).to eq('s')
      expect(hash['githubRepoContext']['startingBranch']).to eq('b')
    end
  end
end
