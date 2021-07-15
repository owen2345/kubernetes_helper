# frozen_string_literal: true

require 'yaml'
require 'json'
module KubernetesHelper
  class Core
    # @return [Hash]
    attr_accessor :config_values

    # @param env_name (String)
    def initialize(env_name)
      env_name = env_name.to_s.length > 1 ? env_name : 'beta'
      @config_values = KubernetesHelper.load_settings(env_name)
      puts "::::;loaded settings: #{@config_values.inspect}"
    end

    def parse_yml_file(file_path, output_path)
      parsed_content = replace_config_variables(File.read(file_path))
      old_yaml = YAML.load(parsed_content) # rubocop:disable Security/YAMLLoad
      json_data = old_yaml.to_json # fix to skip anchors
      yml_data = YAML.load(json_data) # rubocop:disable Security/YAMLLoad
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

    # TODO: use variables replacement logic instead of passing vars to script
    def run_cd_script(script_path)
      deployment_values = @config_values[:continuous_deployment]
      env_vars = deployment_values.map { |k, v| "#{k.upcase}=#{v}" }.join(' ')
      KubernetesHelper.run_cmd("chmod +x #{script_path}")
      KubernetesHelper.run_cmd("#{env_vars} #{script_path}")
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
          container['env'] = container['env'] + import_secrets(*container['import_secrets'])
          container.delete('import_secrets')
        end
      end
    end

    def export_documents(data, file_path)
      documents = data.delete('documents') || [data]
      File.open(file_path, 'w+') do |f|
        documents.each do |document|
          parse_import_secrets(document)
          f << document.to_yaml
        end
      end
    end
  end
end
