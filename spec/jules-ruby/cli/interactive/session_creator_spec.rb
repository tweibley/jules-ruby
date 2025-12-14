# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/interactive/session_creator'

RSpec.describe JulesRuby::Interactive::SessionCreator do
  let(:client) { instance_double(JulesRuby::Client) }
  let(:prompt) { instance_double(TTY::Prompt) }
  let(:sources_resource) { instance_double(JulesRuby::Resources::Sources) }

  subject { described_class.new(client, prompt) }

  before do
    allow(JulesRuby::Prompts).to receive(:clear_screen)
    allow(JulesRuby::Prompts).to receive(:print_banner)
    allow(client).to receive(:sources).and_return(sources_resource)
    allow($stdout).to receive(:puts)
  end

  describe '#run' do
    context 'when no sources are found' do
      before do
        allow(sources_resource).to receive(:all).and_return([])
        allow(prompt).to receive(:error)
        allow(prompt).to receive(:keypress)
        allow(JulesRuby::Prompts).to receive(:with_spinner).and_yield
      end

      it 'displays an error and returns' do
        expect(prompt).to receive(:error).with(/No sources found/)
        expect(prompt).to receive(:keypress)

        subject.run
      end
    end
  end

  describe '#ask_for_prompt' do
    it 'configures the prompt question' do
      question = instance_double(TTY::Prompt::Question)
      allow(prompt).to receive(:ask).and_yield(question)
      expect(question).to receive(:required).with(true)
      expect(question).to receive(:validate).with(/\S/, anything)

      subject.send(:ask_for_prompt)
    end
  end
end
