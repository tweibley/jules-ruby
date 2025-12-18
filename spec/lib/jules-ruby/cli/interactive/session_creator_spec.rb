# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/interactive/session_creator'

RSpec.describe JulesRuby::Interactive::SessionCreator do
  let(:client) { instance_double(JulesRuby::Client) }
  let(:prompt) { instance_spy(TTY::Prompt) }
  let(:creator) { described_class.new(client, prompt) }

  let(:sources_resource) { instance_double(JulesRuby::Resources::Sources) }
  let(:sessions_resource) { instance_double(JulesRuby::Resources::Sessions) }

  let(:session_obj) do
    instance_double(
      JulesRuby::Models::Session,
      name: 'sessions/1',
      url: 'http://example.com/s/1',
      state: 'QUEUED'
    )
  end

  let(:source_obj) do
    instance_double(
      JulesRuby::Models::Source,
      name: 'sources/src_123',
      github_repo: instance_double(JulesRuby::Models::GitHubRepo, full_name: 'owner/repo')
    )
  end

  before do
    allow(client).to receive(:sources).and_return(sources_resource)
    allow(client).to receive(:sessions).and_return(sessions_resource)

    allow(JulesRuby::Prompts).to receive(:clear_screen)
    allow(JulesRuby::Prompts).to receive(:print_banner)
    allow(JulesRuby::Prompts).to receive(:with_spinner).and_yield
    allow($stdout).to receive(:puts)
  end

  describe '#run' do
    context 'when no sources exist' do
      it 'displays error and returns' do
        allow(sources_resource).to receive(:all).and_return([])
        expect(prompt).to receive(:error).with(a_string_matching(/No sources found/))

        creator.run
      end
    end

    context 'when sources exist' do
      before do
        allow(sources_resource).to receive(:all).and_return([source_obj])
        allow(prompt).to receive(:select).and_return(source_obj)
        allow(prompt).to receive(:ask).and_return('main', 'Task', 'My Session')
        allow(prompt).to receive(:yes?).and_return(true)
      end

      it 'creates a session if confirmed' do
        expect(sessions_resource).to receive(:create).with(
          prompt: 'Task',
          source_context: {
            'source' => source_obj.name,
            'githubRepoContext' => { 'startingBranch' => 'main' }
          },
          title: 'My Session',
          automation_mode: 'AUTO_CREATE_PR'
        ).and_return(session_obj)

        creator.run
      end

      it 'aborts if not confirmed' do
        allow(prompt).to receive(:yes?).and_return(true, false)
        expect(sessions_resource).not_to receive(:create)

        creator.run
      end

      it 'truncates long prompts in summary' do
        long_prompt = 'a' * 60
        allow(prompt).to receive(:ask).and_return('main', long_prompt, 'My Session')

        expect(sessions_resource).to receive(:create).and_return(session_obj)
        creator.run
      end
    end
  end
end
