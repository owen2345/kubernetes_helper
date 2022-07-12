# frozen_string_literal: true

require 'spec_helper'
RSpec.describe KubernetesHelper::Core do
  let(:settings) { { sample: { value1: 'sample value1' } } }
  let(:sample_yml) { custom_sample_yml rescue 'name: "<%= sample.value1 %>"' }
  let(:mock_file) { double('File', write: true, '<<' => true) }
  let(:output_yml) { 'file2.yml' }
  let(:inst) { described_class.new('beta') }

  before do
    allow(KubernetesHelper).to receive(:run_cmd)
    inst.config_values.merge!(settings)
    allow(File).to receive(:open).and_yield(mock_file)
    allow(File).to receive(:delete)
  end

  describe 'when parsing deployment yml file' do
    let(:mock_output_file) { double('File', write: true, '<<' => true) }
    let(:input_yml) { 'lib/templates/deployment.yml' }
    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:open).with(output_yml, anything).and_yield(mock_output_file)
    end
    after { |test| inst.parse_yml_file(input_yml, output_yml) unless test.metadata[:skip_after] }

    it 'parses provided yml file' do
      allow(File).to receive(:open).with(input_yml)
    end

    it 'saves parsed yml to provided path' do
      allow(File).to receive(:open).with(output_yml)
    end

    describe 'when defining secrets as env values' do
      describe 'when importing only secrets defined in secrets.yml (base 64 format)' do
        it 'includes all defined secrets in secrets.yml -> data' do
          allow(File).to receive(:read).with(/secrets.yml/) do
            <<~YML
              data:
                secret1: ''
                secret2: ''
            YML
          end
          inst.config_values[:secrets][:import_all_secrets] = false
          expect(mock_output_file).to receive(:write).with(include("name: SECRET1\n          valueFrom:"))
        end
      end

      describe 'when including all secrets (text plain format)' do
        it 'includes the setting to import all secrets (k8s auto imports all keys from the secrets)' do
          inst.config_values[:secrets][:import_all_secrets] = true
          secret_name = inst.config_values[:secrets][:name]
          expect(mock_output_file).to receive(:write).with(include("secretRef:\n            name: #{secret_name}"))
        end
      end

      describe 'when including defined env vars' do
        it 'includes static env vars' do
          inst.config_values[:deployment][:env_vars] = { ENV: 'production' }
          allow(mock_file).to receive(:write) do |content|
            expect(content).to include('name: ENV')
            expect(content).to include('value: production')
          end
        end

        it 'parses a complex external secret' do
          secrets = { PAPERTRAIL_PORT: { name: 'common_secrets', key: 'paper_trail_port' } }
          inst.config_values[:deployment][:env_vars] = secrets
          allow(mock_file).to receive(:write) do |content|
            expect(content).to include('name: PAPERTRAIL_PORT')
            expect(content).to include('name: common_secrets')
            expect(content).to include('key: paper_trail_port')
          end
        end
      end
    end

    describe 'when including multiple job pods' do
      it 'includes pod settings for all job pods', skip_after: true do
        settings = inst.config_values
        job_pods = [{ name: 'pod1', command: 'cmd 1' }, { name: 'pod2', command: 'cmd 2' }]
        settings[:deployment][:job_apps] = job_pods
        job_pods.each do |pod|
          allow(mock_file).to receive(:write).with(include("name: #{pod[:name]}"))
          allow(mock_file).to receive(:write).with(include(pod[:command]))
        end
        inst.parse_yml_file(input_yml, output_yml)
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
