# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/interactive'

RSpec.describe JulesRuby::Interactive do
  let(:client) { instance_double(JulesRuby::Client) }
  let(:prompt) { instance_spy(TTY::Prompt) }
  let(:interactive) { described_class.new }

  # Doubles for delegate classes
  let(:session_creator) { instance_double(JulesRuby::Interactive::SessionCreator) }
  let(:session_manager) { instance_double(JulesRuby::Interactive::SessionManager) }
  let(:source_manager) { instance_double(JulesRuby::Interactive::SourceManager) }

  before do
    allow(JulesRuby::Client).to receive(:new).and_return(client)
    allow(JulesRuby::Prompts).to receive(:prompt).and_return(prompt)

    allow(JulesRuby::Interactive::SessionCreator).to receive(:new).and_return(session_creator)
    allow(JulesRuby::Interactive::SessionManager).to receive(:new).and_return(session_manager)
    allow(JulesRuby::Interactive::SourceManager).to receive(:new).and_return(source_manager)

    allow(JulesRuby::Prompts).to receive(:clear_screen)
    allow(JulesRuby::Prompts).to receive(:print_banner)
    allow($stdout).to receive(:puts)
  end

  describe '#start' do
    it 'calls SessionCreator when :create_session is selected' do
      expect(prompt).to receive(:select).and_return(:create_session, :exit)
      expect(session_creator).to receive(:run)
      interactive.start
    end

    it 'calls SessionManager when :view_sessions is selected' do
      expect(prompt).to receive(:select).and_return(:view_sessions, :exit)
      expect(session_manager).to receive(:run)
      interactive.start
    end

    it 'calls SourceManager when :browse_sources is selected' do
      expect(prompt).to receive(:select).and_return(:browse_sources, :exit)
      expect(source_manager).to receive(:run)
      interactive.start
    end

    it 'exits when :exit is selected' do
      expect(prompt).to receive(:select).and_return(:exit)
      interactive.start
    end
  end
end
