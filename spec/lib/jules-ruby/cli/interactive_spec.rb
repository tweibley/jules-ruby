# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/interactive'

RSpec.describe JulesRuby::Interactive do
  let(:client) { instance_double(JulesRuby::Client) }
  let(:prompt) { instance_spy(TTY::Prompt) }
  let(:interactive) { described_class.new }

  # Resource Doubles
  let(:sessions_resource) { instance_double(JulesRuby::Resources::Sessions) }
  let(:sources_resource) { instance_double(JulesRuby::Resources::Sources) }
  let(:activities_resource) { instance_double(JulesRuby::Resources::Activities) }

  # Model Doubles
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
      awaiting_plan_approval?: false
    )
  end

  let(:source_obj) do
    instance_double(
      JulesRuby::Models::Source,
      id: 'src_123',
      name: 'sources/src_123',
      github_repo: instance_double(JulesRuby::Models::GitHubRepo, full_name: 'owner/repo')
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
    # Mock specific calls used in initialize
    allow(JulesRuby::Client).to receive(:new).and_return(client)
    allow(JulesRuby::Prompts).to receive(:prompt).and_return(prompt)

    # Stub client resources
    allow(client).to receive(:sessions).and_return(sessions_resource)
    allow(client).to receive(:sources).and_return(sources_resource)
    allow(client).to receive(:activities).and_return(activities_resource)

    # Suppress output
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)

    # Mock Prompts helpers
    allow(JulesRuby::Prompts).to receive(:clear_screen)
    allow(JulesRuby::Prompts).to receive(:print_banner)
    allow(JulesRuby::Prompts).to receive(:with_spinner).and_yield

    # Mock common prompt interactions
    allow(prompt).to receive(:keypress)
    allow(prompt).to receive(:warn)
    allow(prompt).to receive(:error)

    # Ensure instance uses our prompt mock
    interactive.instance_variable_set(:@prompt, prompt)
  end

  describe '#start' do
    it 'displays menu and handles exit' do
      allow(prompt).to receive(:select).and_return(:exit)

      expect { interactive.start }.to_not raise_error
    end

    it 'calls create_session_wizard when selected' do
      expect(prompt).to receive(:select).and_return(:create_session, :exit)
      expect(interactive).to receive(:create_session_wizard)

      interactive.start
    end

    it 'calls view_sessions when selected' do
      expect(prompt).to receive(:select).and_return(:view_sessions, :exit)
      expect(interactive).to receive(:view_sessions)

      interactive.start
    end

    it 'calls browse_sources when selected' do
      expect(prompt).to receive(:select).and_return(:browse_sources, :exit)
      expect(interactive).to receive(:browse_sources)

      interactive.start
    end
  end

  describe '#create_session_wizard' do
    context 'when no sources exist' do
      it 'displays error and returns' do
        allow(sources_resource).to receive(:all).and_return([])
        expect(prompt).to receive(:error).with(a_string_matching(/No sources found/))

        interactive.create_session_wizard
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

        interactive.create_session_wizard
      end

      it 'aborts if not confirmed' do
        allow(prompt).to receive(:yes?).and_return(true, false)
        expect(sessions_resource).not_to receive(:create)

        interactive.create_session_wizard
      end
    end
  end

  describe '#view_sessions' do
    context 'when no sessions exist' do
      it 'displays warning and returns' do
        allow(sessions_resource).to receive(:all).and_return([])
        expect(prompt).to receive(:warn).with(a_string_matching(/No sessions found/))

        interactive.view_sessions
      end
    end

    context 'when sessions exist' do
      before do
        allow(sessions_resource).to receive(:all).and_return([session_obj])
      end

      it 'allows creating new session' do
        expect(prompt).to receive(:select).and_return(:create, :back)
        expect(interactive).to receive(:create_session_wizard)

        interactive.view_sessions
      end

      it 'shows session details' do
        expect(prompt).to receive(:select).and_return(session_obj, :back)
        # Mock session_detail to avoid deep recursion in this test
        expect(interactive).to receive(:session_detail).with(session_obj)

        interactive.view_sessions
      end
    end
  end

  describe '#session_detail' do
    before do
      # Mock activity fetching
      allow(activities_resource).to receive(:all).with(session_obj.name).and_return([activity_obj])
    end

    it 'shows details and allows backing out' do
      expect(prompt).to receive(:select).and_return(:back)
      interactive.session_detail(session_obj)
    end

    it 'handles auto-refresh state' do
      allow(session_obj).to receive(:state).and_return('IN_PROGRESS')
      # First call: timeout (refresh)
      # Second call: returns :back

      allow(session_obj).to receive(:state).and_return('IN_PROGRESS')
      allow(client.sessions).to receive(:find).with(session_obj.name).and_return(session_obj)

      # Allow keypress to be called and return 'x'
      allow(prompt).to receive(:keypress).and_return('x')

      # Allow select to be called and return :back
      allow(prompt).to receive(:select).and_return(:back)

      interactive.session_detail(session_obj)

      expect(prompt).to have_received(:select).at_least(:once)
    end

    it 'allows sending a message' do
      expect(prompt).to receive(:select).and_return(:message, :back)
      expect(prompt).to receive(:ask).and_return('hello')
      expect(sessions_resource).to receive(:send_message).with(session_obj.name, prompt: 'hello')
      expect(sessions_resource).to receive(:find).with(session_obj.name).and_return(session_obj)

      interactive.session_detail(session_obj)
    end

    it 'allows approving a plan' do
      # Force session to need approval
      allow(session_obj).to receive(:awaiting_plan_approval?).and_return(true)

      expect(prompt).to receive(:select).and_return(:approve, :back)
      expect(sessions_resource).to receive(:approve_plan).with(session_obj.name)
      expect(sessions_resource).to receive(:find).with(session_obj.name).and_return(session_obj)

      interactive.session_detail(session_obj)
    end

    it 'allows deleting a session' do
      expect(prompt).to receive(:select).and_return(:delete)
      expect(prompt).to receive(:yes?).and_return(true)
      expect(sessions_resource).to receive(:destroy).with(session_obj.name)

      interactive.session_detail(session_obj)
    end

    it 'allows opening url' do
      expect(prompt).to receive(:select).and_return(:open_url, :back)
      expect(interactive).to receive(:system).with('open', session_obj.url)

      interactive.session_detail(session_obj)
    end

    context 'with different activity types' do
      let(:plan_activity) do
        instance_double(
          JulesRuby::Models::Activity,
          type: :plan_generated,
          create_time: Time.now.iso8601,
          plan: instance_double(JulesRuby::Models::Plan,
                                steps: [instance_double(JulesRuby::Models::PlanStep, title: 'Step 1')])
        )
      end

      let(:progress_activity) do
        instance_double(
          JulesRuby::Models::Activity,
          type: :progress_updated,
          create_time: Time.now.iso8601,
          progress_title: 'Working...',
          progress_description: 'Detail'
        )
      end

      let(:fail_activity) do
        instance_double(
          JulesRuby::Models::Activity,
          type: :session_failed,
          create_time: Time.now.iso8601,
          failure_reason: 'Error occurred'
        )
      end

      let(:complete_activity) do
        instance_double(
          JulesRuby::Models::Activity,
          type: :session_completed,
          create_time: Time.now.iso8601
        )
      end

      it 'handles plan_generated' do
        allow(activities_resource).to receive(:all).and_return([plan_activity])
        interactive.view_activities(session_obj)

        allow(session_obj).to receive(:state).and_return('COMPLETED')
        allow(prompt).to receive(:select).and_return(:back)
        interactive.session_detail(session_obj)
      end

      it 'handles progress_updated' do
        allow(activities_resource).to receive(:all).and_return([progress_activity])
        allow(session_obj).to receive(:state).and_return('COMPLETED')
        allow(prompt).to receive(:select).and_return(:back)
        interactive.session_detail(session_obj)
      end

      it 'handles session_failed' do
        allow(activities_resource).to receive(:all).and_return([fail_activity])
        allow(session_obj).to receive(:state).and_return('COMPLETED')
        allow(prompt).to receive(:select).and_return(:back)
        interactive.session_detail(session_obj)
      end

      it 'handles session_completed' do
        allow(activities_resource).to receive(:all).and_return([complete_activity])
        allow(session_obj).to receive(:state).and_return('COMPLETED')
        allow(prompt).to receive(:select).and_return(:back)
        interactive.session_detail(session_obj)
      end

      it 'handles activities with missing data' do
        incomplete_message = instance_double(JulesRuby::Models::Activity, type: :user_messaged,
                                                                          create_time: Time.now.iso8601, message: nil)
        incomplete_progress = instance_double(JulesRuby::Models::Activity, type: :progress_updated,
                                                                           create_time: Time.now.iso8601, progress_title: 'Title', progress_description: nil)
        incomplete_plan = instance_double(JulesRuby::Models::Activity, type: :plan_generated,
                                                                       create_time: Time.now.iso8601, plan: nil)

        allow(activities_resource).to receive(:all).and_return([incomplete_message, incomplete_progress,
                                                                incomplete_plan])
        allow(session_obj).to receive(:state).and_return('COMPLETED')
        allow(prompt).to receive(:select).and_return(:back)
        interactive.session_detail(session_obj)

        interactive.view_activities(session_obj)
      end
    end

    it 'handles activity fetch error' do
      allow(activities_resource).to receive(:all).and_raise(StandardError)
      allow(session_obj).to receive(:state).and_return('COMPLETED')
      allow(prompt).to receive(:select).and_return(:back)

      expect { interactive.session_detail(session_obj) }.not_to raise_error
    end

    it 'handles view activities' do
      expect(prompt).to receive(:select).and_return(:activities, :back)
      expect(interactive).to receive(:view_activities).with(session_obj)
      interactive.session_detail(session_obj)
    end
  end

  describe '#view_activities' do
    it 'displays activities' do
      allow(activities_resource).to receive(:all).and_return([activity_obj])

      # We check that it runs without error, output is suppressed
      expect { interactive.view_activities(session_obj) }.to_not raise_error
    end

    it 'warns if no activities' do
      allow(activities_resource).to receive(:all).and_return([])
      expect(prompt).to receive(:warn).with(a_string_matching(/No activities found/))

      interactive.view_activities(session_obj)
    end
  end

  describe '#browse_sources' do
    it 'lists sources' do
      allow(sources_resource).to receive(:all).and_return([source_obj])
      expect(prompt).to receive(:select).and_return(source_obj) # Select a source

      # It displays details then waits for keypress
      expect(prompt).to receive(:keypress)

      interactive.browse_sources
    end

    it 'warns if no sources' do
      allow(sources_resource).to receive(:all).and_return([])
      expect(prompt).to receive(:warn)

      interactive.browse_sources
    end

    it 'handles back' do
      allow(sources_resource).to receive(:all).and_return([source_obj])
      expect(prompt).to receive(:select).and_return(:back)

      interactive.browse_sources
    end
  end
end
