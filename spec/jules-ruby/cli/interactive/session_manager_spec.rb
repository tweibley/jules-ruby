# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/interactive/session_manager'

RSpec.describe JulesRuby::Interactive::SessionManager do
  let(:client) { instance_double(JulesRuby::Client) }
  let(:prompt) { instance_double(TTY::Prompt) }
  let(:sessions_resource) { instance_double(JulesRuby::Resources::Sessions) }
  let(:activities_resource) { instance_double(JulesRuby::Resources::Activities) }
  let(:renderer) { instance_double(JulesRuby::Interactive::ActivityRenderer) }

  subject { described_class.new(client, prompt) }

  before do
    allow(JulesRuby::Prompts).to receive(:clear_screen)
    allow(JulesRuby::Prompts).to receive(:print_banner)
    allow(JulesRuby::Prompts).to receive(:with_spinner).and_yield
    allow(JulesRuby::Interactive::ActivityRenderer).to receive(:new).and_return(renderer)
    allow(client).to receive(:sessions).and_return(sessions_resource)
    allow(client).to receive(:activities).and_return(activities_resource)
  end

  describe '#run' do
    context 'when no sessions are found' do
      before do
        allow(sessions_resource).to receive(:all).and_return([])
        allow(prompt).to receive(:warn)
        allow(prompt).to receive(:keypress)
      end

      it 'warns and returns' do
        expect(prompt).to receive(:warn).with(/No sessions found/)
        expect(prompt).to receive(:keypress)
        subject.run
      end
    end
  end

  describe '#fetch_latest_activity' do
    let(:session) { instance_double(JulesRuby::Models::Session, name: 'sessions/123') }

    context 'when an error occurs' do
      before do
        allow(activities_resource).to receive(:all).and_raise(StandardError)
      end

      it 'returns nil' do
        expect(subject.send(:fetch_latest_activity, session)).to be_nil
      end
    end
  end

  describe '#display_activity_content' do
    let(:activity) { instance_double(JulesRuby::Models::Activity) }

    context 'when activity is plan_generated' do
      let(:plan) { instance_double(JulesRuby::Models::Plan, steps: [double(title: 'Step 1')]) }

      before do
        allow(activity).to receive(:type).and_return(:plan_generated)
        allow(activity).to receive(:plan).and_return(plan)
      end

      it 'displays the plan steps' do
        expect { subject.send(:display_activity_content, activity) }.to output(/Step 1/).to_stdout
      end
    end

    context 'when activity is session_failed' do
      before do
        allow(activity).to receive(:type).and_return(:session_failed)
        allow(activity).to receive(:failure_reason).and_return('Something went wrong')
      end

      it 'displays the failure reason' do
        expect { subject.send(:display_activity_content, activity) }.to output(/Something went wrong/).to_stdout
      end
    end

    context 'when activity is session_completed' do
      before do
        allow(activity).to receive(:type).and_return(:session_completed)
      end

      it 'displays completion message' do
        expect do
          subject.send(:display_activity_content, activity)
        end.to output(/Session completed successfully/).to_stdout
      end
    end

    context 'when activity is progress_updated' do
      before do
        allow(activity).to receive(:type).and_return(:progress_updated)
        allow(activity).to receive(:progress_title).and_return('Progress Title')
        allow(activity).to receive(:progress_description).and_return('Progress Description')
      end

      it 'displays progress' do
        expect do
          subject.send(:display_activity_content, activity)
        end.to output(/Progress Title.*Progress Description/m).to_stdout
      end
    end
  end

  describe '#handle_session_action' do
    let(:session) { instance_double(JulesRuby::Models::Session, name: 'sessions/123', url: 'http://example.com', id: '123') }

    context 'when action is :open_url' do
      it 'opens the url' do
        expect(subject).to receive(:system).with('open', 'http://example.com')
        subject.send(:handle_session_action, :open_url, session)
      end
    end

    context 'when action is :delete' do
      context 'when confirmed' do
        before do
          allow(prompt).to receive(:yes?).and_return(true)
          allow(sessions_resource).to receive(:destroy)
          allow(prompt).to receive(:keypress)
        end

        it 'deletes the session and returns :deleted' do
          expect(sessions_resource).to receive(:destroy).with(session.name)
          expect(subject.send(:handle_session_action, :delete, session)).to eq(:deleted)
        end
      end
    end
  end

  describe '#view_activities' do
    let(:session) { instance_double(JulesRuby::Models::Session, name: 'sessions/123') }

    context 'when no activities found' do
      before do
        allow(activities_resource).to receive(:all).and_return([])
        allow(prompt).to receive(:warn)
        allow(prompt).to receive(:keypress)
      end

      it 'warns and returns' do
        expect(prompt).to receive(:warn).with(/No activities found/)
        subject.send(:view_activities, session)
      end
    end
  end

  describe '#wrap_text' do
    it 'wraps text correctly' do
      text = "#{'a' * 50} #{'b' * 50}"
      wrapped = subject.send(:wrap_text, text, 76)
      expect(wrapped).to include("\n")
    end
  end

  describe '#update_session_state' do
    let(:session) { instance_double(JulesRuby::Models::Session) }

    it 'returns new session and true if result is a session' do
      new_session = JulesRuby::Models::Session.new({})
      expect(subject.send(:update_session_state, session, new_session, false)).to eq([new_session, true])
    end

    it 'returns session and true if result is :refresh' do
      expect(subject.send(:update_session_state, session, :refresh, false)).to eq([session, true])
    end

    it 'returns session and fetch flag if result is nil' do
      expect(subject.send(:update_session_state, session, nil, false)).to eq([session, false])
    end
  end

  describe '#truncate' do
    it 'truncates text' do
      text = 'a' * 20
      expect(subject.send(:truncate, text, 10)).to eq('aaaaaaaaaa...')
    end

    it 'returns empty string if text is nil' do
      expect(subject.send(:truncate, nil, 10)).to eq('')
    end

    it 'returns text if shorter than length' do
      expect(subject.send(:truncate, 'abc', 10)).to eq('abc')
    end
  end
end
