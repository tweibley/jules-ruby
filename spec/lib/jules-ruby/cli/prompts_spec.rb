# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/prompts'

RSpec.describe JulesRuby::Prompts do
  describe '.prompt' do
    it 'returns a TTY::Prompt instance' do
      expect(described_class.prompt).to be_a(TTY::Prompt)
    end
  end

  describe '.with_spinner' do
    let(:spinner_double) { instance_double(TTY::Spinner) }

    before do
      allow(TTY::Spinner).to receive(:new).and_return(spinner_double)
      allow(spinner_double).to receive(:auto_spin)
      allow(spinner_double).to receive(:success)
      allow(spinner_double).to receive(:error)
    end

    it 'spins and returns result on success' do
      expect(spinner_double).to receive(:auto_spin)
      expect(spinner_double).to receive(:success).with('done')

      result = described_class.with_spinner('checking') { 'success' }
      expect(result).to eq('success')
    end

    it 'spins and stops on error' do
      expect(spinner_double).to receive(:auto_spin)
      expect(spinner_double).to receive(:error).with('failed')

      expect do
        described_class.with_spinner('checking') { raise StandardError, 'fail' }
      end.to raise_error(StandardError, 'fail')
    end
  end

  describe 'state helpers' do
    it 'returns correct emoji' do
      expect(described_class.state_emoji('PLANNING')).to eq('🔵')
      expect(described_class.state_emoji('UNKNOWN')).to eq('❓')
    end

    it 'returns correct label' do
      expect(described_class.state_label('IN_PROGRESS')).to eq('Working')
      expect(described_class.state_label('UNKNOWN')).to eq('UNKNOWN')
    end
  end

  describe 'formatting helpers' do
    describe '.time_ago_in_words' do
      it 'returns N/A for nil' do
        expect(described_class.time_ago_in_words(nil)).to eq('N/A')
      end

      it 'handles seconds ago' do
        time = Time.now - 30
        expect(described_class.time_ago_in_words(time.iso8601)).to eq('just now')
      end

      it 'handles minutes ago' do
        time = Time.now - 120
        expect(described_class.time_ago_in_words(time.iso8601)).to eq('2m ago')
      end

      it 'handles hours ago' do
        time = Time.now - 7200
        expect(described_class.time_ago_in_words(time.iso8601)).to eq('2h ago')
      end

      it 'handles days ago' do
        time = Time.now - 100_000
        expect(described_class.time_ago_in_words(time.iso8601)).to eq('1d ago')
      end
    end

    describe '.format_datetime' do
      it 'returns N/A for nil' do
        expect(described_class.format_datetime(nil)).to eq('N/A')
      end

      it 'formats today' do
        time = Time.now
        formatted = time.strftime('%l:%M %p').strip
        expect(described_class.format_datetime(time.iso8601)).to eq("Today #{formatted}")
      end

      it 'formats yesterday' do
        time = Time.now - 86_400
        formatted = time.strftime('%l:%M %p').strip
        expect(described_class.format_datetime(time.iso8601)).to eq("Yesterday #{formatted}")
      end

      it 'formats older dates' do
        time = Time.now - 200_000
        formatted = time.strftime('%b %d, %Y %l:%M %p').strip
        expect(described_class.format_datetime(time.iso8601)).to eq(formatted)
      end
    end

    describe '.format_session_choice' do
      let(:session) do
        instance_double(
          JulesRuby::Models::Session,
          state: 'PLANNING',
          title: 'My Title',
          prompt: 'My Prompt',
          update_time: Time.now.iso8601
        )
      end

      it 'formats cleanly with title' do
        result = described_class.format_session_choice(session)
        expect(result[:name]).to include('🔵')
        expect(result[:name]).to include('My Title')
        expect(result[:name]).to include('Planning')
      end

      it 'truncates long titles' do
        allow(session).to receive(:title).and_return('Very long title that exceeds the limit')
        result = described_class.format_session_choice(session)
        expect(result[:name]).to include('Very long title that ex...')
      end

      it 'uses truncated prompt if title missing' do
        allow(session).to receive(:title).and_return(nil)
        result = described_class.format_session_choice(session)
        expect(result[:name]).to include('My Prompt')
      end
    end

    describe '.format_source_choice' do
      let(:source) do
        instance_double(
          JulesRuby::Models::Source,
          name: 'foo',
          github_repo: instance_double(JulesRuby::Models::GitHubRepo, full_name: 'owner/repo')
        )
      end

      it 'uses github repo full name' do
        result = described_class.format_source_choice(source)
        expect(result[:name]).to eq('owner/repo')
      end

      it 'falls back to source name' do
        allow(source).to receive(:github_repo).and_return(nil)
        result = described_class.format_source_choice(source)
        expect(result[:name]).to eq('foo')
      end
    end
  end

  describe '.clear_screen' do
    it 'prints clear codes' do
      expect { described_class.clear_screen }.to output("\e[2J\e[H").to_stdout
    end
  end

  describe '.header' do
    it 'prints formatted header' do
      expect { described_class.header('Test') }.to output(/🚀 Test/).to_stdout
    end
  end

  describe '.print_banner' do
    it 'delegates to Banner' do
      expect(JulesRuby::Banner).to receive(:print_banner)
      described_class.print_banner
    end
  end
end
