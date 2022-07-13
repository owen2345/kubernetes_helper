# frozen_string_literal: true

require 'yaml'
require 'json'
require 'erb'
# require 'byebug' rescue nil

module KubernetesHelper
  class ErbBinding < OpenStruct
    def get_binding # rubocop:disable Naming/AccessorMethodName:
      binding
    end

    def include_template(name, locals = {})
      render_template.call(name, locals)
    end
  end

  class Core
    # @return [Hash]
    attr_accessor :config_values

    # @param _env_name (String)
    def initialize(_env_name)
      @config_values = KubernetesHelper.load_settings
    end

    def parse_yml_file(file_path, output_path)
      parsed_content = replace_config_variables(File.read(file_path))
      File.open(output_path, 'w+') { |f| f << parsed_content } # save as draft to be reviewed if failed
      old_yaml = YAML.load_stream(parsed_content)
      json_data = old_yaml.to_json # fix to skip anchors
      yml_data = JSON.parse(json_data)
      export_documents(yml_data, output_path)
    end

    # @param text (String)
    # Sample: replicas: '#{deployment.replicas}'
    def replace_config_variables(text, locals = {})
      values = config_values.merge(locals: locals).map do |key, value| # rubocop:disable Style/HashTransformValues
        [key, value.is_a?(Hash) ? OpenStruct.new(value) : value]
      end.to_h
      values[:render_template] = method(:render_template)
      bind = ErbBinding.new(values).get_binding
      template = ERB.new(text)
      template.result(bind)
    end

    def run_command(command)
      command = replace_config_variables(command)
      KubernetesHelper.run_cmd(command)
    end

    def run_script(script_path)
      content = replace_config_variables(File.read(script_path))
      tmp_file = KubernetesHelper.settings_path('tmp_script.sh')
      File.write(tmp_file, content)
      KubernetesHelper.run_cmd("chmod +x #{tmp_file}")
      KubernetesHelper.run_cmd(tmp_file)
      # File.delete(tmp_file) # keep tmp script for analysis purpose
    end

    private

    # Format: import_secrets: [secrets_yml_path, secrets_name]
    # Sample: import_secrets: ['./secrets.yml', 'packing-beta-secrets']
    def import_secrets(path, secrets_name)
      path = KubernetesHelper.settings_path(path)
      data = YAML.load(File.read(path)) # rubocop:disable Security/YAMLLoad
      (data['data'] || {}).keys.map do |secret|
        {
          'name' => secret.upcase,
          'valueFrom' => { 'secretKeyRef' => { 'name' => secrets_name, 'key' => secret } }
        }
      end
    end

    def render_template(template_name, locals = {})
      path = KubernetesHelper.settings_path(template_name, use_template: true)
      text = "\n#{File.read(path)}"
      text = text.gsub("\n", "\n#{'  ' * locals[:tab]}") if locals[:tab]
      replace_config_variables(text, locals)
    end

    def static_env_vars
      (config_values.dig(:deployment, :env_vars) || {}).map do |key, value|
        external = value.is_a?(Hash)
        value = { 'secretKeyRef' => { 'name' => value[:name], 'key' => value[:key].to_s } } if external
        {
          'name' => key.to_s,
          (external ? 'valueFrom' : 'value') => value
        }
      end
    end

    # parse secrets auto importer
    def parse_import_secrets(document) # rubocop:disable Metrics/AbcSize
      containers = document.dig('spec', 'template', 'spec', 'containers') || []
      containers.each do |container|
        container['env'] = (container['env'] || [])
        container['env'] = container['env'] + static_env_vars if container.delete('static_env')
        if container['import_secrets']
          container['env'] = container['env'] + import_secrets(*container['import_secrets'])
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
        next unless document

        document['documents'] ? documents.push(*document['documents']) : documents.push(document)
      end
      documents
    end
  end
end
