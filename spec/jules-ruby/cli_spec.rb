# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli'
require 'tempfile'

RSpec.describe JulesRuby::CLI do
  let(:sources_response) do
    {
      'sources' => [
        {
          'name' => 'sources/github/owner/repo',
          'githubRepo' => {
            'owner' => 'owner',
            'repo' => 'repo',
            'isPrivate' => false
          }
        }
      ]
    }
  end

  let(:source_response) do
    {
      'name' => 'sources/github/owner/repo',
      'githubRepo' => {
        'owner' => 'owner',
        'repo' => 'repo',
        'isPrivate' => false,
        'url' => 'https://github.com/owner/repo'
      }
    }
  end

  let(:sessions_response) do
    {
      'sessions' => [
        {
          'name' => 'sessions/abc123',
          'id' => 'abc123',
          'title' => 'Test Session',
          'state' => 'ACTIVE',
          'prompt' => 'Fix the bug',
          'updateTime' => '2024-01-15T10:30:00Z'
        }
      ]
    }
  end

  let(:session_response) do
    {
      'name' => 'sessions/abc123',
      'title' => 'Test Session',
      'state' => 'ACTIVE',
      'prompt' => 'Fix the bug',
      'url' => 'https://jules.google.com/sessions/abc123',
      'createTime' => '2024-01-15T10:00:00Z',
      'updateTime' => '2024-01-15T10:30:00Z'
    }
  end

  let(:session_with_outputs_response) do
    {
      'name' => 'sessions/abc123',
      'title' => 'Test Session',
      'state' => 'COMPLETED',
      'prompt' => 'Fix the bug',
      'createTime' => '2024-01-15T10:00:00Z',
      'updateTime' => '2024-01-15T10:30:00Z',
      'outputs' => [
        { 'pullRequest' => { 'url' => 'https://github.com/owner/repo/pull/1' } },
        { 'artifact' => { 'type' => 'CODE' } }
      ]
    }
  end

  let(:activities_response) do
    {
      'activities' => [
        {
          'name' => 'sessions/abc123/activities/xyz789',
          'activityType' => 'AGENT_MESSAGED',
          'originator' => 'AGENT',
          'agentMessaged' => { 'agentMessage' => 'Hello from agent' }
        }
      ]
    }
  end

  let(:activity_response) do
    {
      'name' => 'sessions/abc123/activities/xyz789',
      'activityType' => 'AGENT_MESSAGED',
      'originator' => 'AGENT',
      'createTime' => '2024-01-15T10:00:00Z',
      'agentMessaged' => { 'agentMessage' => 'Hello from agent' }
    }
  end

  before do
    stub_request(:get, 'https://jules.googleapis.com/v1alpha/sources')
      .to_return(status: 200, body: sources_response.to_json, headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, 'https://jules.googleapis.com/v1alpha/sources/github/owner/repo')
      .to_return(status: 200, body: source_response.to_json, headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
      .to_return(status: 200, body: sessions_response.to_json, headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123')
      .to_return(status: 200, body: session_response.to_json, headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123/activities')
      .to_return(status: 200, body: activities_response.to_json, headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123/activities/xyz789')
      .to_return(status: 200, body: activity_response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  # Helper methods at the class level
  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  def capture_stderr
    original = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original
  end

  def capture_output
    stdout_orig = $stdout
    stderr_orig = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    { stdout: $stdout.string, stderr: $stderr.string }
  ensure
    $stdout = stdout_orig
    $stderr = stderr_orig
  end

  describe '.exit_on_failure?' do
    it 'returns true' do
      expect(described_class.exit_on_failure?).to be true
    end
  end

  describe 'version' do
    it 'outputs version string' do
      output = capture_stdout { described_class.start(%w[version]) }
      expect(output).to include('jules-ruby')
      expect(output).to include(JulesRuby::VERSION)
    end

    it 'responds to -v flag' do
      output = capture_stdout { described_class.start(%w[-v]) }
      expect(output).to include(JulesRuby::VERSION)
    end

    it 'responds to --version flag' do
      output = capture_stdout { described_class.start(%w[--version]) }
      expect(output).to include(JulesRuby::VERSION)
    end
  end

  describe 'help' do
    it 'displays banner and examples' do
      # Suppress the interactive mode from starting
      allow(JulesRuby::Interactive).to receive(:new).and_raise(SystemExit)
      allow(JulesRuby::Prompts).to receive(:print_banner)

      output = capture_stdout do
        described_class.start(%w[help])
      rescue SystemExit
        # Expected
      end
      expect(output).to include('QUICK START EXAMPLES')
      expect(output).to include('CONFIGURATION')
    end
  end

  describe 'interactive' do
    it 'starts interactive mode' do
      interactive_mock = instance_double(JulesRuby::Interactive)
      allow(JulesRuby::Interactive).to receive(:new).and_return(interactive_mock)
      allow(interactive_mock).to receive(:start)

      described_class.start(%w[interactive])

      expect(interactive_mock).to have_received(:start)
    end

    it 'responds to -i flag' do
      interactive_mock = instance_double(JulesRuby::Interactive)
      allow(JulesRuby::Interactive).to receive(:new).and_return(interactive_mock)
      allow(interactive_mock).to receive(:start)

      described_class.start(%w[-i])

      expect(interactive_mock).to have_received(:start)
    end
  end

  describe 'sources' do
    describe 'list' do
      it 'outputs JSON when format is json' do
        output = capture_stdout { described_class.start(['sources', 'list', '--format=json']) }
        parsed = JSON.parse(output)
        expect(parsed).to be_an(Array)
        expect(parsed.first['name']).to eq('sources/github/owner/repo')
      end

      it 'outputs table format by default' do
        output = capture_stdout { described_class.start(%w[sources list]) }
        expect(output).to include('NAME')
        expect(output).to include('sources/github/owner/repo')
      end

      context 'when no sources exist' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sources')
            .to_return(status: 200, body: { 'sources' => [] }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays no sources found message' do
          output = capture_stdout { described_class.start(%w[sources list]) }
          expect(output).to include('No sources found')
        end
      end

      context 'when source has no github_repo' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sources')
            .to_return(status: 200,
                       body: { 'sources' => [{ 'name' => 'sources/other/source' }] }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays N/A for repository name' do
          output = capture_stdout { described_class.start(%w[sources list]) }
          expect(output).to include('N/A')
        end
      end
    end

    describe 'show' do
      it 'outputs JSON when format is json' do
        output = capture_stdout do
          described_class.start(['sources', 'show', 'sources/github/owner/repo', '--format=json'])
        end
        parsed = JSON.parse(output)
        expect(parsed['name']).to eq('sources/github/owner/repo')
      end

      it 'displays source details in table format' do
        output = capture_stdout do
          described_class.start(['sources', 'show', 'sources/github/owner/repo'])
        end
        expect(output).to include('Name:')
        expect(output).to include('sources/github/owner/repo')
        expect(output).to include('Repository:')
        expect(output).to include('owner/repo')
      end

      context 'when source has no github_repo' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sources/other/source')
            .to_return(status: 200, body: { 'name' => 'sources/other/source' }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays only basic info' do
          output = capture_stdout do
            described_class.start(['sources', 'show', 'sources/other/source'])
          end
          expect(output).to include('Name:')
          expect(output).not_to include('Repository:')
        end
      end
    end

    describe 'error handling' do
      before do
        stub_request(:get, 'https://jules.googleapis.com/v1alpha/sources/nonexistent')
          .to_return(status: 404, body: { 'error' => { 'message' => 'Not found' } }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'outputs JSON error when format is json' do
        output = capture_stdout do
          expect do
            described_class.start(['sources', 'show', 'sources/nonexistent', '--format=json'])
          end.to raise_error(SystemExit)
        end
        parsed = JSON.parse(output)
        expect(parsed).to have_key('error')
      end

      it 'outputs text error by default' do
        output = capture_stderr do
          expect { described_class.start(['sources', 'show', 'sources/nonexistent']) }.to raise_error(SystemExit)
        end
        expect(output).to include('Error:')
      end

      context 'when list fails' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sources')
            .to_return(status: 500, body: { 'error' => { 'message' => 'Server error' } }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'outputs JSON error for list' do
          output = capture_stdout do
            expect do
              described_class.start(['sources', 'list', '--format=json'])
            end.to raise_error(SystemExit)
          end
          parsed = JSON.parse(output)
          expect(parsed).to have_key('error')
        end
      end
    end
  end

  describe 'sessions' do
    describe 'list' do
      it 'outputs JSON when format is json' do
        output = capture_stdout { described_class.start(['sessions', 'list', '--format=json']) }
        parsed = JSON.parse(output)
        expect(parsed).to be_an(Array)
        expect(parsed.first['name']).to eq('sessions/abc123')
      end

      it 'outputs table format by default' do
        output = capture_stdout { described_class.start(%w[sessions list]) }
        expect(output).to include('ID')
        expect(output).to include('TITLE')
        expect(output).to include('STATE')
        expect(output).to include('Test Session')
      end

      context 'when no sessions exist' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
            .to_return(status: 200, body: { 'sessions' => [] }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays no sessions found message' do
          output = capture_stdout { described_class.start(%w[sessions list]) }
          expect(output).to include('No sessions found')
        end
      end

      context 'when session has no title' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
            .to_return(status: 200,
                       body: { 'sessions' => [{ 'name' => 'sessions/abc', 'id' => 'abc', 'state' => 'ACTIVE',
                                                'prompt' => 'A very long prompt that exceeds ' \
                                                            'twenty-eight characters' }] }
                               .to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays truncated prompt as title' do
          output = capture_stdout { described_class.start(%w[sessions list]) }
          expect(output).to include('A very long prompt that e...')
        end
      end

      context 'when session has no update_time' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
            .to_return(status: 200,
                       body: { 'sessions' => [{ 'name' => 'sessions/abc', 'id' => 'abc', 'title' => 'Test',
                                                'state' => 'ACTIVE' }] }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays N/A for updated time' do
          output = capture_stdout { described_class.start(%w[sessions list]) }
          expect(output).to include('N/A')
        end
      end
    end

    describe 'show' do
      it 'outputs JSON when format is json' do
        output = capture_stdout { described_class.start(['sessions', 'show', 'abc123', '--format=json']) }
        parsed = JSON.parse(output)
        expect(parsed['name']).to eq('sessions/abc123')
      end

      it 'displays session details in table format' do
        output = capture_stdout { described_class.start(%w[sessions show abc123]) }
        expect(output).to include('Name:')
        expect(output).to include('sessions/abc123')
        expect(output).to include('State:')
        expect(output).to include('URL:')
      end

      context 'with outputs' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123')
            .to_return(status: 200, body: session_with_outputs_response.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays PR outputs' do
          output = capture_stdout { described_class.start(%w[sessions show abc123]) }
          expect(output).to include('Outputs:')
          expect(output).to include('PR:')
          expect(output).to include('https://github.com/owner/repo/pull/1')
        end
      end

      context 'with non-PR outputs' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123')
            .to_return(status: 200, body: {
              'name' => 'sessions/abc123',
              'state' => 'COMPLETED',
              'createTime' => '2024-01-15T10:00:00Z',
              'updateTime' => '2024-01-15T10:30:00Z',
              'outputs' => [{ 'other' => 'data' }]
            }.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays other outputs' do
          output = capture_stdout { described_class.start(%w[sessions show abc123]) }
          expect(output).to include('Outputs:')
        end
      end

      context 'without optional fields' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123')
            .to_return(status: 200, body: {
              'name' => 'sessions/abc123',
              'state' => 'ACTIVE',
              'createTime' => '2024-01-15T10:00:00Z',
              'updateTime' => '2024-01-15T10:30:00Z'
            }.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'handles missing title, prompt, url' do
          output = capture_stdout { described_class.start(%w[sessions show abc123]) }
          expect(output).to include('Name:')
          expect(output).not_to include('Title:')
        end
      end
    end

    describe 'create' do
      let(:create_response) do
        {
          'name' => 'sessions/new123',
          'state' => 'QUEUED',
          'url' => 'https://jules.google.com/sessions/new123'
        }
      end

      before do
        stub_request(:post, 'https://jules.googleapis.com/v1alpha/sessions')
          .to_return(status: 200, body: create_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'creates a session with inline prompt' do
        output = capture_stdout do
          described_class.start([
                                  'sessions', 'create',
                                  '--source=sources/github/owner/repo',
                                  '--prompt=Fix the bug'
                                ])
        end
        expect(output).to include('Session created:')
        expect(output).to include('sessions/new123')
      end

      it 'creates a session with prompt from file' do
        Tempfile.create('prompt') do |f|
          f.write('Fix the bug from file')
          f.close

          output = capture_stdout do
            described_class.start([
                                    'sessions', 'create',
                                    '--source=sources/github/owner/repo',
                                    "--prompt-file=#{f.path}"
                                  ])
          end
          expect(output).to include('Session created:')
        end
      end

      it 'creates a session with title' do
        output = capture_stdout do
          described_class.start([
                                  'sessions', 'create',
                                  '--source=sources/github/owner/repo',
                                  '--prompt=Fix the bug',
                                  '--title=Bug Fix Session'
                                ])
        end
        expect(output).to include('Session created:')
      end

      it 'creates a session with auto-pr' do
        output = capture_stdout do
          described_class.start([
                                  'sessions', 'create',
                                  '--source=sources/github/owner/repo',
                                  '--prompt=Fix the bug',
                                  '--auto-pr'
                                ])
        end
        expect(output).to include('Session created:')
      end

      it 'raises error when prompt file does not exist' do
        expect do
          capture_stderr do
            described_class.start([
                                    'sessions', 'create',
                                    '--source=sources/github/owner/repo',
                                    '--prompt-file=/nonexistent/file.txt'
                                  ])
          end
        end.to raise_error(SystemExit)
      end

      it 'raises error when no prompt provided' do
        expect do
          capture_stderr do
            described_class.start([
                                    'sessions', 'create',
                                    '--source=sources/github/owner/repo'
                                  ])
          end
        end.to raise_error(SystemExit)
      end

      context 'when API fails' do
        before do
          stub_request(:post, 'https://jules.googleapis.com/v1alpha/sessions')
            .to_return(status: 400, body: { 'error' => { 'message' => 'Bad request' } }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'outputs error' do
          output = capture_stderr do
            expect do
              described_class.start([
                                      'sessions', 'create',
                                      '--source=sources/github/owner/repo',
                                      '--prompt=Fix the bug'
                                    ])
            end.to raise_error(SystemExit)
          end
          expect(output).to include('Error:')
        end
      end
    end

    describe 'approve' do
      before do
        stub_request(:post, 'https://jules.googleapis.com/v1alpha/sessions/abc123:approvePlan')
          .to_return(status: 200, body: session_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'approves a session plan' do
        output = capture_stdout { described_class.start(%w[sessions approve abc123]) }
        expect(output).to include('Plan approved')
        expect(output).to include('State:')
      end

      context 'when API fails' do
        before do
          stub_request(:post, 'https://jules.googleapis.com/v1alpha/sessions/abc123:approvePlan')
            .to_return(status: 400, body: { 'error' => { 'message' => 'Bad request' } }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'outputs error' do
          output = capture_stderr do
            expect { described_class.start(%w[sessions approve abc123]) }.to raise_error(SystemExit)
          end
          expect(output).to include('Error:')
        end
      end
    end

    describe 'message' do
      before do
        stub_request(:post, 'https://jules.googleapis.com/v1alpha/sessions/abc123:sendMessage')
          .to_return(status: 200, body: session_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'sends a message to a session' do
        output = capture_stdout do
          described_class.start(['sessions', 'message', 'abc123', '--prompt=Please add tests'])
        end
        expect(output).to include('Message sent')
        expect(output).to include('State:')
      end

      context 'when API fails' do
        before do
          stub_request(:post, 'https://jules.googleapis.com/v1alpha/sessions/abc123:sendMessage')
            .to_return(status: 400, body: { 'error' => { 'message' => 'Bad request' } }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'outputs error' do
          output = capture_stderr do
            expect do
              described_class.start(['sessions', 'message', 'abc123', '--prompt=test'])
            end.to raise_error(SystemExit)
          end
          expect(output).to include('Error:')
        end
      end
    end

    describe 'delete' do
      before do
        stub_request(:delete, 'https://jules.googleapis.com/v1alpha/sessions/abc123')
          .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'deletes a session' do
        output = capture_stdout { described_class.start(%w[sessions delete abc123]) }
        expect(output).to include('Session deleted')
        expect(output).to include('abc123')
      end

      context 'when API fails' do
        before do
          stub_request(:delete, 'https://jules.googleapis.com/v1alpha/sessions/abc123')
            .to_return(status: 404, body: { 'error' => { 'message' => 'Not found' } }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'outputs error' do
          output = capture_stderr do
            expect { described_class.start(%w[sessions delete abc123]) }.to raise_error(SystemExit)
          end
          expect(output).to include('Error:')
        end
      end
    end

    describe 'error handling' do
      context 'when list fails with JSON format' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions')
            .to_return(status: 500, body: { 'error' => { 'message' => 'Server error' } }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'outputs JSON error' do
          output = capture_stdout do
            expect do
              described_class.start(['sessions', 'list', '--format=json'])
            end.to raise_error(SystemExit)
          end
          parsed = JSON.parse(output)
          expect(parsed).to have_key('error')
        end
      end

      context 'when show fails with JSON format' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/notfound')
            .to_return(status: 404, body: { 'error' => { 'message' => 'Not found' } }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'outputs JSON error' do
          output = capture_stdout do
            expect do
              described_class.start(['sessions', 'show', 'notfound', '--format=json'])
            end.to raise_error(SystemExit)
          end
          parsed = JSON.parse(output)
          expect(parsed).to have_key('error')
        end
      end
    end
  end

  describe 'activities' do
    describe 'list' do
      it 'outputs JSON when format is json' do
        output = capture_stdout { described_class.start(['activities', 'list', 'abc123', '--format=json']) }
        parsed = JSON.parse(output)
        expect(parsed).to be_an(Array)
      end

      it 'outputs table format by default' do
        output = capture_stdout { described_class.start(%w[activities list abc123]) }
        expect(output).to include('ID')
        expect(output).to include('TYPE')
        expect(output).to include('FROM')
        expect(output).to include('DESCRIPTION')
      end

      context 'when no activities exist' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123/activities')
            .to_return(status: 200, body: { 'activities' => [] }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays no activities found message' do
          output = capture_stdout { described_class.start(%w[activities list abc123]) }
          expect(output).to include('No activities found')
        end
      end

      context 'with different activity types' do
        let(:mixed_activities) do
          {
            'activities' => [
              { 'name' => 'a1', 'activityType' => 'AGENT_MESSAGED', 'agentMessaged' => { 'agentMessage' => 'Hello' } },
              { 'name' => 'a2', 'activityType' => 'USER_MESSAGED', 'userMessaged' => { 'userMessage' => 'Hi' } },
              { 'name' => 'a3', 'activityType' => 'PLAN_GENERATED',
                'planGenerated' => { 'plan' => { 'steps' => [{ 'title' => 'Step 1' }] } } },
              { 'name' => 'a4', 'activityType' => 'PROGRESS_UPDATED', 'progressUpdated' => { 'title' => 'Working' } },
              { 'name' => 'a5', 'activityType' => 'SESSION_COMPLETED', 'sessionCompleted' => {} },
              { 'name' => 'a6', 'activityType' => 'SESSION_FAILED', 'sessionFailed' => { 'reason' => 'Timeout' } },
              { 'name' => 'a7', 'activityType' => 'UNKNOWN_TYPE', 'description' => 'Unknown activity' }
            ]
          }
        end

        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123/activities')
            .to_return(status: 200, body: mixed_activities.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays summary for each activity type' do
          output = capture_stdout { described_class.start(%w[activities list abc123]) }
          expect(output).to include('Hello')            # agent_messaged summary
          expect(output).to include('1 steps')          # plan_generated summary shows step count
          expect(output).to include('Working')          # progress_updated summary
          expect(output).to include('Session completed') # session_completed summary
        end
      end

      context 'with nil originator' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123/activities')
            .to_return(status: 200,
                       body: { 'activities' => [{ 'name' => 'a1',
                                                  'activityType' => 'SESSION_COMPLETED' }] }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays N/A for originator' do
          output = capture_stdout { described_class.start(%w[activities list abc123]) }
          expect(output).to include('N/A')
        end
      end
    end

    describe 'show' do
      it 'outputs JSON when format is json' do
        output = capture_stdout do
          described_class.start(['activities', 'show', 'sessions/abc123/activities/xyz789', '--format=json'])
        end
        parsed = JSON.parse(output)
        expect(parsed['name']).to eq('sessions/abc123/activities/xyz789')
      end

      it 'displays activity details in table format' do
        output = capture_stdout do
          described_class.start(['activities', 'show', 'sessions/abc123/activities/xyz789'])
        end
        expect(output).to include('Name:')
        expect(output).to include('Type:')
        expect(output).to include('Originator:')
        expect(output).to include('Message:')
        expect(output).to include('Hello from agent')
      end

      context 'with user_messaged activity' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123/activities/user1')
            .to_return(status: 200, body: {
              'name' => 'sessions/abc123/activities/user1',
              'activityType' => 'USER_MESSAGED',
              'originator' => 'USER',
              'createTime' => '2024-01-15T10:00:00Z',
              'userMessaged' => { 'userMessage' => 'Hello from user' }
            }.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays user message' do
          output = capture_stdout do
            described_class.start(['activities', 'show', 'sessions/abc123/activities/user1'])
          end
          expect(output).to include('Message:')
          expect(output).to include('Hello from user')
        end
      end

      context 'with plan_generated activity' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123/activities/plan1')
            .to_return(status: 200, body: {
              'name' => 'sessions/abc123/activities/plan1',
              'activityType' => 'PLAN_GENERATED',
              'originator' => 'AGENT',
              'createTime' => '2024-01-15T10:00:00Z',
              'planGenerated' => {
                'plan' => {
                  'steps' => [
                    { 'title' => 'Step 1: Analyze' },
                    { 'title' => 'Step 2: Implement' }
                  ]
                }
              }
            }.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays plan steps' do
          output = capture_stdout do
            described_class.start(['activities', 'show', 'sessions/abc123/activities/plan1'])
          end
          expect(output).to include('Plan:')
          expect(output).to include('1. Step 1: Analyze')
          expect(output).to include('2. Step 2: Implement')
        end
      end

      context 'with progress_updated activity' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123/activities/prog1')
            .to_return(status: 200, body: {
              'name' => 'sessions/abc123/activities/prog1',
              'activityType' => 'PROGRESS_UPDATED',
              'originator' => 'SYSTEM',
              'createTime' => '2024-01-15T10:00:00Z',
              'progressUpdated' => {
                'title' => 'Working on step 1',
                'description' => 'Analyzing codebase'
              }
            }.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays progress details' do
          output = capture_stdout do
            described_class.start(['activities', 'show', 'sessions/abc123/activities/prog1'])
          end
          expect(output).to include('Progress:')
          expect(output).to include('Working on step 1')
          expect(output).to include('Details:')
          expect(output).to include('Analyzing codebase')
        end
      end

      context 'with session_failed activity' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123/activities/fail1')
            .to_return(status: 200, body: {
              'name' => 'sessions/abc123/activities/fail1',
              'activityType' => 'SESSION_FAILED',
              'originator' => 'SYSTEM',
              'createTime' => '2024-01-15T10:00:00Z',
              'sessionFailed' => { 'reason' => 'Timeout exceeded' }
            }.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays failure reason' do
          output = capture_stdout do
            described_class.start(['activities', 'show', 'sessions/abc123/activities/fail1'])
          end
          expect(output).to include('Failure Reason:')
          expect(output).to include('Timeout exceeded')
        end
      end

      context 'with artifacts' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123/activities/art1')
            .to_return(status: 200, body: {
              'name' => 'sessions/abc123/activities/art1',
              'activityType' => 'AGENT_MESSAGED',
              'originator' => 'AGENT',
              'createTime' => '2024-01-15T10:00:00Z',
              'agentMessaged' => { 'agentMessage' => 'Here are the changes' },
              'artifacts' => [
                { 'changeSet' => { 'source' => 'file.rb' } },
                { 'media' => { 'mimeType' => 'image/png' } }
              ]
            }.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays artifacts' do
          output = capture_stdout do
            described_class.start(['activities', 'show', 'sessions/abc123/activities/art1'])
          end
          expect(output).to include('Artifacts:')
          expect(output).to include('Type: change_set')
          expect(output).to include('Type: media')
        end
      end

      context 'with description field' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123/activities/desc1')
            .to_return(status: 200, body: {
              'name' => 'sessions/abc123/activities/desc1',
              'activityType' => 'SESSION_COMPLETED',
              'originator' => 'SYSTEM',
              'createTime' => '2024-01-15T10:00:00Z',
              'description' => 'Session completed successfully'
            }.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'displays description' do
          output = capture_stdout do
            described_class.start(['activities', 'show', 'sessions/abc123/activities/desc1'])
          end
          expect(output).to include('Description:')
          expect(output).to include('Session completed successfully')
        end
      end
    end

    describe 'error handling' do
      context 'when list fails' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/notfound/activities')
            .to_return(status: 404, body: { 'error' => { 'message' => 'Not found' } }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'outputs JSON error when format is json' do
          output = capture_stdout do
            expect do
              described_class.start(['activities', 'list', 'notfound', '--format=json'])
            end.to raise_error(SystemExit)
          end
          parsed = JSON.parse(output)
          expect(parsed).to have_key('error')
        end

        it 'outputs text error by default' do
          output = capture_stderr do
            expect { described_class.start(%w[activities list notfound]) }.to raise_error(SystemExit)
          end
          expect(output).to include('Error:')
        end
      end

      context 'when show fails' do
        before do
          stub_request(:get, 'https://jules.googleapis.com/v1alpha/sessions/abc123/activities/notfound')
            .to_return(status: 404, body: { 'error' => { 'message' => 'Not found' } }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'outputs JSON error when format is json' do
          output = capture_stdout do
            expect do
              described_class.start(['activities', 'show', 'sessions/abc123/activities/notfound', '--format=json'])
            end.to raise_error(SystemExit)
          end
          parsed = JSON.parse(output)
          expect(parsed).to have_key('error')
        end

        it 'outputs text error by default' do
          output = capture_stderr do
            expect do
              described_class.start(['activities', 'show', 'sessions/abc123/activities/notfound'])
            end.to raise_error(SystemExit)
          end
          expect(output).to include('Error:')
        end
      end
    end
  end
end
