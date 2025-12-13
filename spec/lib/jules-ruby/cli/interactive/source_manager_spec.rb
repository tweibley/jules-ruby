# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/interactive/source_manager'

RSpec.describe JulesRuby::Interactive::SourceManager do
  let(:client) { instance_double(JulesRuby::Client) }
  let(:prompt) { instance_spy(TTY::Prompt) }
  let(:manager) { described_class.new(client, prompt) }

  let(:sources_resource) { instance_double(JulesRuby::Resources::Sources) }

  let(:source_obj) do
    instance_double(
      JulesRuby::Models::Source,
      id: 'src_123',
      name: 'sources/src_123',
      github_repo: instance_double(JulesRuby::Models::GitHubRepo, full_name: 'owner/repo')
    )
  end

  before do
    allow(client).to receive(:sources).and_return(sources_resource)
    allow(JulesRuby::Prompts).to receive(:clear_screen)
    allow(JulesRuby::Prompts).to receive(:print_banner)
    allow(JulesRuby::Prompts).to receive(:with_spinner).and_yield
    allow($stdout).to receive(:puts)
  end

  describe '#run' do
    it 'lists sources' do
      allow(sources_resource).to receive(:all).and_return([source_obj])
      expect(prompt).to receive(:select).and_return(source_obj) # Select a source

      # It displays details then waits for keypress
      expect(prompt).to receive(:keypress)

      manager.run
    end

    it 'warns if no sources' do
      allow(sources_resource).to receive(:all).and_return([])
      expect(prompt).to receive(:warn)

      manager.run
    end

    it 'handles back' do
      allow(sources_resource).to receive(:all).and_return([source_obj])
      expect(prompt).to receive(:select).and_return(:back)

      manager.run
    end
  end
end
