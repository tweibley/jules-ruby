# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Models::PlanStep do
  let(:step_data) do
    {
      'id' => 'step-1',
      'title' => 'Step 1',
      'description' => 'Do this',
      'index' => 1
    }
  end

  subject(:step) { described_class.new(step_data) }

  describe 'attributes' do
    it 'parses attributes' do
      expect(step.id).to eq('step-1')
      expect(step.title).to eq('Step 1')
      expect(step.description).to eq('Do this')
      expect(step.index).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      hash = step.to_h
      expect(hash[:id]).to eq('step-1')
      expect(hash[:title]).to eq('Step 1')
      expect(hash[:description]).to eq('Do this')
      expect(hash[:index]).to eq(1)
    end
  end
end
