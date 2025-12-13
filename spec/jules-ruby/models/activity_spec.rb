# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Models::Activity do
  describe 'basic attributes' do
    let(:activity_data) do
      {
        'name' => 'sessions/123/activities/abc',
        'id' => 'abc',
        'description' => 'Test activity',
        'createTime' => '2025-01-01T00:00:00Z',
        'originator' => 'agent',
        'artifacts' => [{ 'changeSet' => { 'source' => 'test' } }]
      }
    end

    subject(:activity) { described_class.new(activity_data) }

    it 'parses basic attributes' do
      expect(activity.name).to eq('sessions/123/activities/abc')
      expect(activity.id).to eq('abc')
      expect(activity.description).to eq('Test activity')
      expect(activity.create_time).to eq('2025-01-01T00:00:00Z')
      expect(activity.originator).to eq('agent')
    end

    it 'parses artifacts' do
      expect(activity.artifacts.first).to be_a(JulesRuby::Models::Artifact)
    end

    it 'converts to hash' do
      hash = activity.to_h
      expect(hash[:name]).to eq('sessions/123/activities/abc')
      expect(hash[:type]).to eq(:unknown)
    end
  end

  describe 'agent_messaged activity' do
    let(:activity_data) do
      {
        'name' => 'sessions/123/activities/msg1',
        'originator' => 'agent',
        'agentMessaged' => { 'agentMessage' => 'Hello from agent' }
      }
    end

    subject(:activity) { described_class.new(activity_data) }

    it 'identifies type as agent_messaged' do
      expect(activity.type).to eq(:agent_messaged)
      expect(activity.agent_message?).to be true
    end

    it 'provides message content' do
      expect(activity.message).to eq('Hello from agent')
    end
  end

  describe 'user_messaged activity' do
    let(:activity_data) do
      {
        'name' => 'sessions/123/activities/msg2',
        'originator' => 'user',
        'userMessaged' => { 'userMessage' => 'Hello from user' }
      }
    end

    subject(:activity) { described_class.new(activity_data) }

    it 'identifies type as user_messaged' do
      expect(activity.type).to eq(:user_messaged)
      expect(activity.user_message?).to be true
    end

    it 'identifies originator as user' do
      expect(activity.from_user?).to be true
      expect(activity.from_agent?).to be false
      expect(activity.from_system?).to be false
    end

    it 'provides message content' do
      expect(activity.message).to eq('Hello from user')
    end
  end

  describe 'plan_generated activity' do
    let(:activity_data) do
      {
        'name' => 'sessions/123/activities/plan1',
        'originator' => 'agent',
        'planGenerated' => {
          'plan' => {
            'id' => 'plan123',
            'steps' => [{ 'id' => 'step1', 'title' => 'Setup', 'index' => 0 }]
          }
        }
      }
    end

    subject(:activity) { described_class.new(activity_data) }

    it 'identifies type as plan_generated' do
      expect(activity.type).to eq(:plan_generated)
      expect(activity.plan_generated?).to be true
    end

    it 'parses the plan' do
      expect(activity.plan).to be_a(JulesRuby::Models::Plan)
      expect(activity.plan.id).to eq('plan123')
    end
  end

  describe 'plan_generated without plan data' do
    let(:activity_data) do
      {
        'name' => 'sessions/123/activities/plan2',
        'planGenerated' => {}
      }
    end

    subject(:activity) { described_class.new(activity_data) }

    it 'handles empty planGenerated' do
      expect(activity.plan).to be_nil
    end
  end

  describe 'plan_approved activity' do
    let(:activity_data) do
      {
        'name' => 'sessions/123/activities/approved',
        'planApproved' => { 'planId' => 'plan123' }
      }
    end

    subject(:activity) { described_class.new(activity_data) }

    it 'identifies type as plan_approved' do
      expect(activity.type).to eq(:plan_approved)
      expect(activity.plan_approved?).to be true
    end

    it 'provides approved plan id' do
      expect(activity.approved_plan_id).to eq('plan123')
    end
  end

  describe 'progress_updated activity' do
    let(:activity_data) do
      {
        'name' => 'sessions/123/activities/progress',
        'originator' => 'system',
        'progressUpdated' => {
          'title' => 'Running tests',
          'description' => 'Executing test suite'
        }
      }
    end

    subject(:activity) { described_class.new(activity_data) }

    it 'identifies type as progress_updated' do
      expect(activity.type).to eq(:progress_updated)
      expect(activity.progress_update?).to be true
    end

    it 'identifies originator as system' do
      expect(activity.from_system?).to be true
    end

    it 'provides progress details' do
      expect(activity.progress_title).to eq('Running tests')
      expect(activity.progress_description).to eq('Executing test suite')
    end
  end

  describe 'session_completed activity' do
    let(:activity_data) do
      {
        'name' => 'sessions/123/activities/completed',
        'sessionCompleted' => {}
      }
    end

    subject(:activity) { described_class.new(activity_data) }

    it 'identifies type as session_completed' do
      expect(activity.type).to eq(:session_completed)
      expect(activity.session_completed?).to be true
    end
  end

  describe 'session_failed activity' do
    let(:activity_data) do
      {
        'name' => 'sessions/123/activities/failed',
        'sessionFailed' => { 'reason' => 'Something went wrong' }
      }
    end

    subject(:activity) { described_class.new(activity_data) }

    it 'identifies type as session_failed' do
      expect(activity.type).to eq(:session_failed)
      expect(activity.session_failed?).to be true
    end

    it 'provides failure reason' do
      expect(activity.failure_reason).to eq('Something went wrong')
    end
  end
end
