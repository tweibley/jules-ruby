# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli'

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
        'isPrivate' => false
      }
    }
  end

  let(:sessions_response) do
    {
      'sessions' => [
        {
          'name' => 'sessions/abc123',
          'title' => 'Test Session',
          'state' => 'ACTIVE',
          'prompt' => 'Fix the bug'
        }
      ]
    }
  end

  let(:session_response) do
    {
      'name' => 'sessions/abc123',
      'title' => 'Test Session',
      'state' => 'ACTIVE',
      'prompt' => 'Fix the bug'
    }
  end

  let(:activities_response) do
    {
      'activities' => [
        {
          'name' => 'sessions/abc123/activities/xyz789',
          'activityType' => 'AGENT_MESSAGED',
          'originator' => 'AGENT'
        }
      ]
    }
  end

  let(:activity_response) do
    {
      'name' => 'sessions/abc123/activities/xyz789',
      'activityType' => 'AGENT_MESSAGED',
      'originator' => 'AGENT'
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

  describe 'sources' do
    describe 'list --format=json' do
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
    end

    describe 'show --format=json' do
      it 'outputs JSON when format is json' do
        output = capture_stdout do
          described_class.start(['sources', 'show', 'sources/github/owner/repo', '--format=json'])
        end
        parsed = JSON.parse(output)
        expect(parsed['name']).to eq('sources/github/owner/repo')
      end
    end

    describe 'error handling with --format=json' do
      before do
        stub_request(:get, 'https://jules.googleapis.com/v1alpha/sources/nonexistent')
          .to_return(status: 404, body: { 'error' => { 'message' => 'Not found' } }.to_json, headers: { 'Content-Type' => 'application/json' })
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
    end
  end

  describe 'sessions' do
    describe 'list --format=json' do
      it 'outputs JSON when format is json' do
        output = capture_stdout { described_class.start(['sessions', 'list', '--format=json']) }
        parsed = JSON.parse(output)
        expect(parsed).to be_an(Array)
        expect(parsed.first['name']).to eq('sessions/abc123')
      end

      it 'outputs table format by default' do
        output = capture_stdout { described_class.start(%w[sessions list]) }
        expect(output).to include('ID')
        expect(output).to include('Test Session')
      end
    end

    describe 'show --format=json' do
      it 'outputs JSON when format is json' do
        output = capture_stdout { described_class.start(['sessions', 'show', 'abc123', '--format=json']) }
        parsed = JSON.parse(output)
        expect(parsed['name']).to eq('sessions/abc123')
      end
    end
  end

  describe 'activities' do
    describe 'list --format=json' do
      it 'outputs JSON when format is json' do
        output = capture_stdout { described_class.start(['activities', 'list', 'abc123', '--format=json']) }
        parsed = JSON.parse(output)
        expect(parsed).to be_an(Array)
      end

      it 'outputs table format by default' do
        output = capture_stdout { described_class.start(%w[activities list abc123]) }
        expect(output).to include('ID')
        expect(output).to include('TYPE')
      end
    end

    describe 'show --format=json' do
      it 'outputs JSON when format is json' do
        output = capture_stdout do
          described_class.start(['activities', 'show', 'sessions/abc123/activities/xyz789', '--format=json'])
        end
        parsed = JSON.parse(output)
        expect(parsed['name']).to eq('sessions/abc123/activities/xyz789')
      end
    end
  end

  private

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
end
