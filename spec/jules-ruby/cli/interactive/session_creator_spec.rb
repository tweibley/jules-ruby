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
    it 'requests multiline input' do
      allow(prompt).to receive(:multiline).and_return(["Input\n"])
      expect(prompt).to receive(:multiline).with(/What would you like Jules to do/)

      result = subject.send(:ask_for_prompt)
      expect(result).to eq('Input')
    end

    it 'loops until input is provided' do
      # First return empty, then valid input
      allow(prompt).to receive(:multiline).and_return([], ["Valid input\n"])
      expect(prompt).to receive(:error).with(/Prompt cannot be empty/)

      result = subject.send(:ask_for_prompt)
      expect(result).to eq('Valid input')
    end

    it 'configures the prompt' do
      question = double('question')
      allow(prompt).to receive(:multiline).and_yield(question).and_return(['input'])
      expect(question).to receive(:help).with(/Ctrl\+D/)
      expect(question).to receive(:default)
      subject.send(:ask_for_prompt)
    end
  end
end
