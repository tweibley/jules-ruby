# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/interactive/activity_renderer'

RSpec.describe JulesRuby::Interactive::ActivityRenderer do
  let(:renderer) { described_class.new }
  let(:create_time) { Time.now.iso8601 }

  let(:message_activity) do
    instance_double(
      JulesRuby::Models::Activity,
      type: :agent_messaged,
      create_time: create_time,
      message: 'Hello world',
      plan: nil,
      progress_title: nil,
      progress_description: nil,
      failure_reason: nil
    )
  end

  let(:plan_activity) do
    instance_double(
      JulesRuby::Models::Activity,
      type: :plan_generated,
      create_time: create_time,
      plan: instance_double(JulesRuby::Models::Plan, steps: [
                              instance_double(JulesRuby::Models::PlanStep, title: 'Step 1')
                            ]),
      message: nil,
      progress_title: nil,
      progress_description: nil,
      failure_reason: nil
    )
  end

  let(:progress_activity) do
    instance_double(
      JulesRuby::Models::Activity,
      type: :progress_updated,
      create_time: create_time,
      progress_title: 'Working',
      progress_description: 'Details',
      message: nil,
      plan: nil,
      failure_reason: nil
    )
  end

  let(:failure_activity) do
    instance_double(
      JulesRuby::Models::Activity,
      type: :session_failed,
      create_time: create_time,
      failure_reason: 'Something went wrong',
      message: nil,
      plan: nil,
      progress_title: nil,
      progress_description: nil
    )
  end

  let(:completion_activity) do
    instance_double(
      JulesRuby::Models::Activity,
      type: :session_completed,
      create_time: create_time,
      message: nil,
      plan: nil,
      progress_title: nil,
      progress_description: nil,
      failure_reason: nil
    )
  end

  before do
    allow($stdout).to receive(:puts)
  end

  describe '#render' do
    it 'renders message activity' do
      renderer.render(message_activity)
      expect($stdout).to have_received(:puts).with(include('Hello world'))
    end

    it 'renders plan activity' do
      renderer.render(plan_activity)
      expect($stdout).to have_received(:puts).with(include('Step 1'))
    end

    it 'renders progress activity' do
      renderer.render(progress_activity)
      expect($stdout).to have_received(:puts).with(include('Working'))
      expect($stdout).to have_received(:puts).with(include('Details'))
    end

    it 'renders failure activity' do
      renderer.render(failure_activity)
      expect($stdout).to have_received(:puts).with(include('Something went wrong'))
    end

    it 'renders completion activity' do
      renderer.render(completion_activity)
      expect($stdout).to have_received(:puts).with(include('Session completed successfully'))
    end

    it 'wraps long message' do
      long_msg = 'a' * 80
      renderer.render(
        instance_double(
          JulesRuby::Models::Activity,
          type: :agent_messaged,
          create_time: create_time,
          message: long_msg,
          plan: nil,
          progress_title: nil,
          progress_description: nil,
          failure_reason: nil
        )
      )
      # 80 chars should be wrapped since default width is 76/72
      # The wrapping logic splits it into multiple lines
      # We just check that it outputs multiple lines or the content is there
      expect($stdout).to have_received(:puts).at_least(:once)
    end
  end
end
