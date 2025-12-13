# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Models::Source do
  let(:data) do
    {
      'name' => 'sources/1',
      'id' => '1',
      'githubRepo' => { 'owner' => 'o', 'repo' => 'r' }
    }
  end
  subject(:source) { described_class.new(data) }

  it 'parses attributes' do
    expect(source.name).to eq('sources/1')
    expect(source.id).to eq('1')
    expect(source.github_repo).to be_a(JulesRuby::Models::GitHubRepo)
  end

  it 'handles missing repo' do
    data['githubRepo'] = nil
    expect(described_class.new(data).github_repo).to be_nil
  end

  it 'to_h' do
    expect(source.to_h).to include(:name, :id, :github_repo)
  end
end
