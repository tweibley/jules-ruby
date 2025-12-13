# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/sessions'

RSpec.describe JulesRuby::Commands::Sessions do
  let(:client) { instance_double(JulesRuby::Client) }
  let(:sessions_resource) { instance_double(JulesRuby::Resources::Sessions) }
  let(:commands) { described_class.new }

  before do
    allow(JulesRuby::Client).to receive(:new).and_return(client)
    allow(client).to receive(:sessions).and_return(sessions_resource)
    allow(commands).to receive(:options).and_return({})
    allow($stdout).to receive(:puts)
  end

  describe '#list' do
    it 'displays sessions' do
      session = instance_double(JulesRuby::Models::Session, id: '1', title: 'T', state: 'S', update_time: nil,
                                                            prompt: 'P', to_h: {})
      allow(sessions_resource).to receive(:all).and_return([session])
      commands.list
      expect($stdout).to have_received(:puts).with(include('T')).at_least(:once)
    end

    it 'displays JSON' do
      session = instance_double(JulesRuby::Models::Session, id: '1', to_h: { id: '1' })
      allow(sessions_resource).to receive(:all).and_return([session])
      allow(commands).to receive(:options).and_return({ format: 'json' })
      expect { commands.list }.to output(include('"id": "1"')).to_stdout
    end
  end

  describe '#show' do
    let(:session) { instance_double(JulesRuby::Models::Session, id: '1', name: 'n', title: 't', prompt: 'p', state: 's', url: 'u', create_time: 'c', update_time: 'u', outputs: [], to_h: {}) }

    before do
      allow(sessions_resource).to receive(:find).with('1').and_return(session)
    end

    it 'displays details' do
      commands.show('1')
      expect($stdout).to have_received(:puts).with(include('Name:    n'))
    end

    it 'displays outputs with URL' do
      output = double('Output', url: 'http://pr')
      allow(session).to receive(:outputs).and_return([output])
      commands.show('1')
      expect($stdout).to have_received(:puts).with(include('PR: http://pr'))
    end

    it 'displays outputs as text' do
      allow(session).to receive(:outputs).and_return(['some text'])
      commands.show('1')
      expect($stdout).to have_received(:puts).with(include('- some text'))
    end
  end

  # Basic verification for create/approve/message/delete to ensure class methods work
  describe '#create' do
    it 'creates session' do
      allow(commands).to receive(:options).and_return({ prompt: 'fix', source: 'src' })
      allow(sessions_resource).to receive(:create).and_return(instance_double(JulesRuby::Models::Session, name: 'n',
                                                                                                          url: 'u', state: 's'))
      commands.create
      expect(sessions_resource).to have_received(:create)
    end
  end
end
