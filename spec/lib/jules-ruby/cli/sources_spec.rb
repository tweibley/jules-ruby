# frozen_string_literal: true

require 'spec_helper'
require 'jules-ruby/cli/sources'

RSpec.describe JulesRuby::Commands::Sources do
  let(:client) { instance_double(JulesRuby::Client) }
  let(:sources_resource) { instance_double(JulesRuby::Resources::Sources) }
  let(:commands) { described_class.new }

  before do
    allow(JulesRuby::Client).to receive(:new).and_return(client)
    allow(client).to receive(:sources).and_return(sources_resource)
    allow(commands).to receive(:options).and_return({})
    allow($stdout).to receive(:puts)
  end

  describe '#list' do
    let(:repo) { double('GitHubRepo', full_name: 'owner/repo') }
    let(:source) do
      instance_double(
        JulesRuby::Models::Source,
        name: 'src1',
        github_repo: repo,
        to_h: {}
      )
    end

    before do
      allow(sources_resource).to receive(:all).and_return([source])
    end

    it 'displays sources table' do
      commands.list
      expect($stdout).to have_received(:puts).with(include('src1'))
      expect($stdout).to have_received(:puts).with(include('owner/repo'))
    end

    it 'displays JSON' do
      allow(commands).to receive(:options).and_return({ format: 'json' })
      # Need to handle to_h call if format is json
      allow(source).to receive(:to_h).and_return({ name: 'src1' })
      expect { commands.list }.to output(include('"name": "src1"')).to_stdout
    end

    it 'handles empty list' do
      allow(sources_resource).to receive(:all).and_return([])
      commands.list
      expect($stdout).to have_received(:puts).with('No sources found.')
    end

    it 'handles source without repo' do
      allow(source).to receive(:github_repo).and_return(nil)
      commands.list
      expect($stdout).to have_received(:puts).with(include('N/A'))
    end
  end

  describe '#show' do
    let(:repo) { double('GitHubRepo', full_name: 'o/r', url: 'http://repo') }
    let(:source) do
      instance_double(
        JulesRuby::Models::Source,
        name: 'src1',
        id: '1',
        github_repo: repo,
        to_h: {}
      )
    end

    before do
      allow(sources_resource).to receive(:find).with('src1').and_return(source)
    end

    it 'displays details' do
      commands.show('src1')
      expect($stdout).to have_received(:puts).with(include('Name:       src1'))
      expect($stdout).to have_received(:puts).with(include('Repository: o/r'))
      expect($stdout).to have_received(:puts).with(include('URL:        http://repo'))
    end

    it 'displays details without repo' do
      allow(source).to receive(:github_repo).and_return(nil)
      commands.show('src1')
      expect($stdout).to have_received(:puts).with(include('Name:       src1'))
      expect($stdout).not_to have_received(:puts).with(include('Repository:'))
    end

    it 'displays details without repo URL' do
      repo_no_url = double('Repo', full_name: 'o/r')
      allow(source).to receive(:github_repo).and_return(repo_no_url)

      commands.show('src1')
      expect($stdout).to have_received(:puts).with(include('Repository: o/r'))
      expect($stdout).not_to have_received(:puts).with(include('URL:'))
    end
  end
end
