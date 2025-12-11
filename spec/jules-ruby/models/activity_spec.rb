# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Models::Activity do
  describe 'plan_generated activity' do
    let(:activity_data) do
      {
        'name' => 'sessions/123/activities/abc',
        'id' => 'abc',
        'createTime' => '2025-01-01T00:00:00Z',
        'originator' => 'agent',
        'planGenerated' => {
          'plan' => {
            'id' => 'plan123',
            'steps' => [
              { 'id' => 'step1', 'title' => 'Setup', 'index' => 0 }
            ]
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
      expect(activity.plan.steps.first.title).to eq('Setup')
    end

    it 'identifies originator' do
      expect(activity.from_agent?).to be true
      expect(activity.from_user?).to be false
    end
  end

  describe 'progress_updated activity' do
    let(:activity_data) do
      {
        'name' => 'sessions/123/activities/def',
        'id' => 'def',
        'originator' => 'agent',
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

    it 'provides progress helpers' do
      expect(activity.progress_title).to eq('Running tests')
      expect(activity.progress_description).to eq('Executing test suite')
    end
  end
end
