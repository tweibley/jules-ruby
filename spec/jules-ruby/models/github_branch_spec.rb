# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Models::GitHubBranch do
  subject(:branch) { described_class.new({ 'displayName' => 'main' }) }

  it 'parses attributes' do
    expect(branch.display_name).to eq('main')
  end

  it 'to_h' do
    expect(branch.to_h).to eq({ display_name: 'main' })
  end
end
