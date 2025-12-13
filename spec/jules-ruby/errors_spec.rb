# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Error do
  it 'stores response and status_code' do
    error = described_class.new('msg', response: { a: 1 }, status_code: 400)
    expect(error.message).to eq('msg')
    expect(error.response).to eq({ a: 1 })
    expect(error.status_code).to eq(400)
  end
end
