# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JulesRuby::Models::Artifact do
  context 'when it is a change set' do
    let(:data) do
      {
        'changeSet' => {
          'source' => 'src',
          'gitPatch' => {
            'unidiffPatch' => 'diff',
            'baseCommitId' => 'sha',
            'suggestedCommitMessage' => 'msg'
          }
        }
      }
    end
    subject(:artifact) { described_class.new(data) }

    it 'detects type' do
      expect(artifact.type).to eq(:change_set)
    end

    it 'exposes helpers' do
      expect(artifact.source).to eq('src')
      expect(artifact.unidiff_patch).to eq('diff')
      expect(artifact.base_commit_id).to eq('sha')
      expect(artifact.suggested_commit_message).to eq('msg')
    end

    it 'returns nil for other helpers' do
      expect(artifact.media_data).to be_nil
      expect(artifact.bash_command).to be_nil
    end
  end

  context 'when it is media' do
    let(:data) { { 'media' => { 'data' => 'xyz', 'mimeType' => 'image/png' } } }
    subject(:artifact) { described_class.new(data) }

    it 'detects type' do
      expect(artifact.type).to eq(:media)
    end

    it 'exposes helpers' do
      expect(artifact.media_data).to eq('xyz')
      expect(artifact.media_mime_type).to eq('image/png')
    end
  end

  context 'when it is bash output' do
    let(:data) { { 'bashOutput' => { 'command' => 'ls', 'output' => 'file', 'exitCode' => 0 } } }
    subject(:artifact) { described_class.new(data) }

    it 'detects type' do
      expect(artifact.type).to eq(:bash_output)
    end

    it 'exposes helpers' do
      expect(artifact.bash_command).to eq('ls')
      expect(artifact.bash_output_text).to eq('file')
      expect(artifact.bash_exit_code).to eq(0)
    end
  end

  context 'when unknown' do
    subject(:artifact) { described_class.new({}) }
    it 'detects type' do
      expect(artifact.type).to eq(:unknown)
    end
  end

  describe '#to_h' do
    it 'returns hash' do
      expect(described_class.new({}).to_h.keys).to include(:change_set, :media, :bash_output)
    end
  end
end
