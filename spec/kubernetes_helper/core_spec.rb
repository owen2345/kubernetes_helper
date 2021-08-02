# frozen_string_literal: true

require 'spec_helper'
RSpec.describe KubernetesHelper::Core do
  let(:settings) { { sample: { value1: 'sample value1' } } }
  let(:sample_yml) { custom_sample_yml rescue 'name: "<%= sample.value1 %>"' }
  let(:mock_file) { double('File', write: true) }
  let(:inst) { described_class.new('beta') }

  before do
    allow(KubernetesHelper).to receive(:run_cmd)
    allow(KubernetesHelper).to receive(:load_settings).and_return(settings)
    allow(File).to receive(:open).and_yield(mock_file)
    allow(File).to receive(:delete)
  end

  describe 'when parsing yml file' do
    let(:input_yml) { 'file1.yml' }
    let(:output_yml) { 'file2.yml' }
    before do
      allow(File).to receive(:read).with(input_yml).and_return(sample_yml)
    end
    after { inst.parse_yml_file(input_yml, output_yml) }

    it 'replaces config values' do
      expect(mock_file).to receive(:write).with(/#{settings[:sample][:value1]}/)
    end

    it 'parses provided yml file' do
      allow(File).to receive(:open).with(input_yml)
    end

    it 'saves parsed yml to provided path' do
      allow(File).to receive(:open).with(output_yml)
    end

    it 'auto includes static env vars' do
      # pending '....'
    end

    describe 'when replacing secrets as env values' do
      let(:secret_file_name) { 'secrets.yml' }
      let(:secret_name) { 'secret_name' }
      let(:custom_sample_yml) do
        %{
spec:
    template:
      spec:
        containers:
          - import_secrets: ['#{secret_file_name}', '#{secret_name}']
        }
      end
      before { allow(File).to receive(:read).with(/#{secret_file_name}$/).and_call_original }

      it 'loads secrets from provided yml file' do
        expect(File).to receive(:read).with(/#{secret_file_name}$/)
      end

      it 'replaces secrets' do
        expect(mock_file).to receive(:write).with(/name: #{secret_name}/)
      end
    end

    describe 'when yml includes multiple documents' do
      let(:sample_yml) { "documents:\n    - name: 'Document 1'\n    - name: 'Document 2'" }

      it 'support for multiple documents to share yml variables' do
        expect(mock_file).to receive(:write).twice
      end
    end
  end

  describe 'when running command' do
    it 'replaces config value' do
      expect(KubernetesHelper).to receive(:run_cmd).with('echo sample value1')
      inst.run_command('echo <%= sample.value1 %>')
    end
  end

  describe 'when executing bash file' do
    it 'replaces config value' do
      script_path = KubernetesHelper.settings_path('cd.sh')
      allow(File).to receive(:read).with(script_path).and_return('echo <%= sample.value1 %>')
      expect(File).to receive(:write).with(/tmp_script.sh$/, 'echo sample value1')
      inst.run_script(script_path)
    end
  end
end
