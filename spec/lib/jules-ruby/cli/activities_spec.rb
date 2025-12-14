# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/activities'

RSpec.describe JulesRuby::Commands::Activities do
  let(:client) { instance_double(JulesRuby::Client) }
  let(:activities_resource) { instance_double(JulesRuby::Resources::Activities) }
  let(:commands) { described_class.new }

  before do
    allow(JulesRuby::Client).to receive(:new).and_return(client)
    allow(client).to receive(:activities).and_return(activities_resource)
    allow(commands).to receive(:options).and_return({})
    allow(commands).to receive(:warn)
  end

  describe '#list' do
    let(:activity) do
      instance_double(
        JulesRuby::Models::Activity,
        id: '1',
        type: :agent_messaged,
        originator: 'AGENT',
        message: 'Hello',
        description: nil,
        create_time: Time.now.iso8601,
        plan: nil,
        progress_title: nil,
        failure_reason: nil
      )
    end

    before do
      allow(activities_resource).to receive(:all).with('sess_id').and_return([activity])
      allow($stdout).to receive(:puts)
    end

    it 'displays activities' do
      commands.list('sess_id')
      expect($stdout).to have_received(:puts).with(include('Hello'))
    end

    it 'displays JSON when format is json' do
      allow(commands).to receive(:options).and_return({ format: 'json' })
      allow(activity).to receive(:to_h).and_return({ id: '1' })
      expect { commands.list('sess_id') }.to output(include('"id": "1"')).to_stdout
    end

    it 'handles error' do
      allow(activities_resource).to receive(:all).and_raise(JulesRuby::Error.new('Fail'))
      expect { commands.list('sess_id') }.to raise_error(SystemExit)
    end

    context 'with various activity types' do
      it 'handles plan_generated' do
        allow(activity).to receive_messages(type: :plan_generated,
                                            plan: instance_double(
                                              JulesRuby::Models::Plan, steps: []
                                            ))
        commands.list('sess_id')
        expect($stdout).to have_received(:puts).with(include('Plan with 0 steps'))
      end

      it 'handles progress_updated' do
        allow(activity).to receive_messages(type: :progress_updated, progress_title: 'Working')
        commands.list('sess_id')
        expect($stdout).to have_received(:puts).with(include('Working'))
      end

      it 'handles session_completed' do
        allow(activity).to receive_messages(type: :session_completed)
        commands.list('sess_id')
        expect($stdout).to have_received(:puts).with(include('Session completed'))
      end

      it 'handles session_failed' do
        allow(activity).to receive_messages(type: :session_failed, failure_reason: 'Timeout')
        commands.list('sess_id')
        expect($stdout).to have_received(:puts).with(include('Timeout'))
      end

      it 'handles unknown type fallback' do
        allow(activity).to receive_messages(type: :unknown, description: 'Something else')
        commands.list('sess_id')
        expect($stdout).to have_received(:puts).with(include('Something else'))
      end
    end
  end

  describe '#show' do
    let(:activity) { instance_double(JulesRuby::Models::Activity, id: '1', name: 'act1', type: :agent_messaged, originator: 'AGENT', create_time: Time.now.iso8601, description: 'Desc', message: 'Msg', artifacts: []) }

    before do
      allow(activities_resource).to receive(:find).with('act1').and_return(activity)
      allow($stdout).to receive(:puts)
    end

    it 'displays details' do
      commands.show('act1')
      expect($stdout).to have_received(:puts).with(include('Msg'))
    end

    it 'displays JSON' do
      allow(commands).to receive(:options).and_return({ format: 'json' })
      allow(activity).to receive(:to_h).and_return({ id: '1' })
      expect { commands.show('act1') }.to output(include('"id": "1"')).to_stdout
    end
  end
end
