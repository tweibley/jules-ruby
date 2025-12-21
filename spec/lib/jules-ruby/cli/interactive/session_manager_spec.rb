# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/interactive/session_manager'

RSpec.describe JulesRuby::Interactive::SessionManager do
  let(:client) { instance_double(JulesRuby::Client) }
  let(:prompt) { instance_spy(TTY::Prompt) }
  let(:manager) { described_class.new(client, prompt) }

  let(:sessions_resource) { instance_double(JulesRuby::Resources::Sessions) }
  let(:activities_resource) { instance_double(JulesRuby::Resources::Activities) }

  # Stub ActivityRenderer to avoid needing full logic
  let(:activity_renderer) { instance_double(JulesRuby::Interactive::ActivityRenderer) }

  let(:session_obj) do
    instance_double(
      JulesRuby::Models::Session,
      id: 'sess_123',
      name: 'sessions/sess_123',
      title: 'Test Session',
      state: 'COMPLETED',
      prompt: 'Do something',
      url: 'http://example.com/s/1',
      create_time: Time.now.iso8601,
      update_time: Time.now.iso8601,
      awaiting_plan_approval?: false,
      outputs: []
    )
  end

  let(:activity_obj) do
    instance_double(
      JulesRuby::Models::Activity,
      type: :user_messaged,
      create_time: Time.now.iso8601,
      message: 'Hello',
      plan: nil,
      progress_title: nil,
      progress_description: nil,
      failure_reason: nil
    )
  end

  before do
    allow(client).to receive(:sessions).and_return(sessions_resource)
    allow(client).to receive(:activities).and_return(activities_resource)

    allow(JulesRuby::Interactive::ActivityRenderer).to receive(:new).and_return(activity_renderer)
    allow(activity_renderer).to receive(:render)

    allow(JulesRuby::Prompts).to receive(:clear_screen)
    allow(JulesRuby::Prompts).to receive(:print_banner)
    allow(JulesRuby::Prompts).to receive(:with_spinner).and_yield

    allow(prompt).to receive(:keypress)
    allow(prompt).to receive(:warn)

    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)
  end

  describe '#run' do
    context 'when no sessions exist' do
      it 'displays warning and returns' do
        allow(sessions_resource).to receive(:all).and_return([])
        expect(prompt).to receive(:warn).with(a_string_matching(/No sessions found/))

        manager.run
      end
    end

    context 'when sessions exist' do
      before do
        allow(sessions_resource).to receive(:all).and_return([session_obj])

        allow(JulesRuby::Interactive::SessionCreator).to receive(:new).and_return(
          instance_double(JulesRuby::Interactive::SessionCreator, run: nil)
        )
      end

      it 'allows creating new session' do
        expect(prompt).to receive(:select).and_return(:create, :back)
        expect(JulesRuby::Interactive::SessionCreator).to receive(:new).with(client, prompt)

        manager.run
      end

      it 'shows session details' do
        expect(prompt).to receive(:select).and_return(session_obj, :back)
        # Mock session_detail to avoid deep recursion in this test
        expect(manager).to receive(:session_detail).with(session_obj)

        manager.run
      end
    end
  end

  describe '#session_detail' do
    before do
      allow(activities_resource).to receive(:all).with(session_obj.name).and_return([activity_obj])
    end

    it 'shows details and allows backing out' do
      expect(prompt).to receive(:select).and_return(:back)
      manager.send(:session_detail, session_obj)
    end

    it 'allows sending a message' do
      expect(prompt).to receive(:select).and_return(:message, :back)
      expect(prompt).to receive(:multiline).and_return(["hello\n"])
      expect(sessions_resource).to receive(:send_message).with(session_obj.name, prompt: 'hello')
      expect(sessions_resource).to receive(:find).with(session_obj.name).and_return(session_obj)

      manager.send(:session_detail, session_obj)
    end

    it 'allows approving a plan' do
      allow(session_obj).to receive(:awaiting_plan_approval?).and_return(true)

      expect(prompt).to receive(:select).and_return(:approve, :back)
      expect(sessions_resource).to receive(:approve_plan).with(session_obj.name)
      expect(sessions_resource).to receive(:find).with(session_obj.name).and_return(session_obj)

      manager.send(:session_detail, session_obj)
    end

    it 'allows deleting a session' do
      expect(prompt).to receive(:select).and_return(:delete)
      expect(prompt).to receive(:yes?).and_return(true)
      expect(sessions_resource).to receive(:destroy).with(session_obj.name)

      # Returns :deleted which breaks the loop
      manager.send(:session_detail, session_obj)
    end

    it 'allows viewing activities' do
      expect(prompt).to receive(:select).and_return(:activities, :back)
      # This will trigger view_activities which calls renderer
      expect(activity_renderer).to receive(:render).with(activity_obj)

      manager.send(:session_detail, session_obj)
    end

    it 'handles auto-refresh state' do
      allow(session_obj).to receive(:state).and_return('IN_PROGRESS')
      allow(sessions_resource).to receive(:find).with(session_obj.name).and_return(session_obj)

      # First iteration: timeout (returns nil from keypress)
      expect(prompt).to receive(:keypress).with(timeout: 60).and_return(nil)

      # Second iteration: key pressed
      expect(prompt).to receive(:keypress).with(timeout: 60).and_return('x')
      expect(prompt).to receive(:select).and_return(:back)

      manager.send(:session_detail, session_obj)
    end
  end
end
