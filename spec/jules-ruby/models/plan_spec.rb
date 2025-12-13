# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Models::Plan do
  let(:plan_data) do
    {
      'id' => 'plan-123',
      'steps' => [
        { 'id' => 'step-1', 'title' => 'Step 1', 'description' => 'Do this', 'index' => 1 },
        { 'id' => 'step-2', 'title' => 'Step 2', 'description' => 'Do that', 'index' => 2 }
      ],
      'createTime' => '2025-01-01T00:00:00Z'
    }
  end

  subject(:plan) { described_class.new(plan_data) }

  describe 'attributes' do
    it 'parses attributes' do
      expect(plan.id).to eq('plan-123')
      expect(plan.create_time).to eq('2025-01-01T00:00:00Z')
    end

    it 'parses steps' do
      expect(plan.steps).to be_an(Array)
      expect(plan.steps.size).to eq(2)
      expect(plan.steps.first).to be_a(JulesRuby::Models::PlanStep)
      expect(plan.steps.first.title).to eq('Step 1')
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      hash = plan.to_h
      expect(hash[:id]).to eq('plan-123')
      expect(hash[:steps]).to be_an(Array)
      expect(hash[:steps].first[:title]).to eq('Step 1')
    end
  end
end
