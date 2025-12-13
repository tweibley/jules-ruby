# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/prompts'

RSpec.describe JulesRuby::Prompts do
  describe '.state_emoji' do
    it 'returns emoji for known state' do
      expect(described_class.state_emoji('COMPLETED')).to eq('🟢')
    end

    it 'returns fallback for unknown state' do
      expect(described_class.state_emoji('UNKNOWN')).to eq('❓')
    end
  end

  describe '.state_label' do
    it 'returns label for known state' do
      expect(described_class.state_label('IN_PROGRESS')).to eq('Working')
    end

    it 'returns state for unknown state' do
      expect(described_class.state_label('UNKNOWN')).to eq('UNKNOWN')
    end
  end

  describe '.time_ago_in_words' do
    it 'handles nil' do
      expect(described_class.time_ago_in_words(nil)).to eq('N/A')
    end

    it 'returns just now' do
      expect(described_class.time_ago_in_words(Time.now.iso8601)).to eq('just now')
    end

    it 'returns minutes ago' do
      t = (Time.now - 120).iso8601
      expect(described_class.time_ago_in_words(t)).to eq('2m ago')
    end

    it 'returns hours ago' do
      t = (Time.now - 3660).iso8601
      expect(described_class.time_ago_in_words(t)).to eq('1h ago')
    end

    it 'returns days ago' do
      t = (Time.now - 86_401).iso8601
      expect(described_class.time_ago_in_words(t)).to eq('1d ago')
    end
  end

  describe '.format_datetime' do
    it 'handles nil' do
      expect(described_class.format_datetime(nil)).to eq('N/A')
    end

    it 'formats today' do
      t = Time.now
      expect(described_class.format_datetime(t.iso8601)).to include("Today")
    end

    it 'formats yesterday' do
      t = Time.now - 86_400
      expect(described_class.format_datetime(t.iso8601)).to include("Yesterday")
    end
  end

  describe '.format_session_choice' do
    it 'formats correctly' do
      session = double('Session',
        state: 'IN_PROGRESS',
        title: 'Test Session',
        prompt: 'Do something',
        update_time: Time.now.iso8601
      )
      choice = described_class.format_session_choice(session)
      expect(choice[:name]).to include('🔵 Test Session')
      expect(choice[:value]).to eq(session)
    end
  end
end
