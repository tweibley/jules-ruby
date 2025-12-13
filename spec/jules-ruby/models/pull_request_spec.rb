# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Models::PullRequest do
  subject(:pr) { described_class.new({ 'url' => 'u', 'title' => 't', 'description' => 'd' }) }

  it 'parses attributes' do
    expect(pr.url).to eq('u')
    expect(pr.title).to eq('t')
    expect(pr.description).to eq('d')
  end

  it 'to_h' do
    expect(pr.to_h).to eq({ url: 'u', title: 't', description: 'd' })
  end
end
