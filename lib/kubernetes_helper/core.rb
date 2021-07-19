# frozen_string_literal: true

require 'yaml'
require 'json'
# require 'byebug' rescue nil

module KubernetesHelper
  class Core
    # @return [Hash]
    attr_accessor :config_values

    # @param env_name (String)
    def initialize(env_name)
      env_name = env_name.to_s.length > 1 ? env_name : 'beta'
      @config_values = KubernetesHelper.load_settings(env_name)
    end

    def parse_yml_file(file_path, output_path)
      parsed_content = replace_config_variables(File.read(file_path))
      old_yaml = YAML.load_stream(parsed_content)
      json_data = old_yaml.to_json # fix to skip anchors
      yml_data = JSON.parse(json_data)
      export_documents(yml_data, output_path)
    end

    # @param text (String)
    # Sample: replicas: '#{deployment.replicas}'
    def replace_config_variables(text)
      text.gsub(/(\#{([^}])*})/) do |code|
        find_setting_value(code.gsub('#{', '').gsub('}', ''))
      end
    end

    def run_command(command)
      command = replace_config_variables(command)
      KubernetesHelper.run_cmd(command)
    end

    def run_cd_script(script_path)
      content = replace_config_variables(File.read(script_path))
      tmp_file = KubernetesHelper.settings_path('tmp_cd.sh')
      File.write(tmp_file, content)
      KubernetesHelper.run_cmd("chmod +x #{tmp_file}")
      KubernetesHelper.run_cmd(tmp_file)
      File.delete(tmp_file)
    end

    private

    # Format: import_secrets: [secrets_yml_path, secrets_name]
    # Sample: import_secrets: ['./secrets.yml', 'packing-beta-secrets']
    def import_secrets(path, secrets_name)
      path = KubernetesHelper.settings_path(path)
      data = YAML.load(File.read(path)) # rubocop:disable Security/YAMLLoad
      data['data'].keys.map do |secret|
        {
          'name' => secret.upcase,
          'valueFrom' => { 'secretKeyRef' => { 'name' => secrets_name, 'key' => secret } }
        }
      end
    end

    # @param setting_key (String)
    # sample: deployment.replicas
    def find_setting_value(setting_key)
      parent = @config_values
      setting_key.split('.').each do |key|
        parent = parent[key.to_sym]
      end
      parent
    end

    # parse secrets auto importer
    def parse_import_secrets(document)
      containers = document.dig('spec', 'template', 'spec', 'containers') || []
      containers.each do |container|
        if container['import_secrets']
          container['env'] = (container['env'] || []) + import_secrets(*container['import_secrets'])
          container.delete('import_secrets')
        end
      end
    end

    def export_documents(yml_data, file_path)
      File.open(file_path, 'w+') do |f|
        parse_documents(yml_data).each do |document|
          parse_import_secrets(document)
          f.write(document.to_yaml)
        end
      end
    end

    # @return [Array<Hash>]
    def parse_documents(yml_data)
      documents = []
      Array(yml_data).each do |document|
        document['documents'] ? documents.push(*document['documents']) : documents.push(document)
      end
      documents
    end
  end
end
