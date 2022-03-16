# frozen_string_literal: true

require 'kubernetes_helper/core'
require 'kubernetes_helper/railtie' if defined?(Rails)

module KubernetesHelper
  class Error < StandardError; end
  FOLDER_NAME = '.kubernetes'

  def self.settings(settings = nil)
    @settings = settings if settings
    @settings
  end

  # @param env_name (String)
  # @return [Hash]
  def self.load_settings # rubocop:disable Metrics/MethodLength:
    config_file = File.join(settings_path, 'settings.rb')
    load config_file

    def_settings = {
      cloud: {
        name: 'gcloud'
      },
      deployment: {
        log_container: true,
        log_folder: '/app/log'
      },
      service: {
        port_name: 'http-port',
        backend_port_name: 'b-port'
      },
      secrets: {},
      continuous_deployment: {},
      ingress: {}
    }
    deep_merge(def_settings, settings || {})
  end

  def self.deep_merge(hash1, hash2)
    merger = proc { |_key, v1, v2| v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &merger) : v2 }
    hash1.merge(hash2, &merger)
  end

  def self.settings_path(file_name = nil, use_template: false)
    path = File.join(Dir.pwd, FOLDER_NAME)
    if file_name
      app_path = File.join(path, file_name)
      path = use_template && !File.exist?(app_path) ? templates_path(file_name) : app_path
    end
    path
  end

  def self.run_cmd(cmd, title = nil)
    res = Kernel.system cmd
    Kernel.abort("::::::::CD: failed running command: #{title || cmd} ==> #{caller}") if res != true
  end

  def self.templates_path(file_name = nil)
    path = File.join(File.expand_path(__dir__), 'templates')
    file_name ? File.join(path, file_name) : path
  end

  # @param mode_or_file (basic, advanced, String) mode name or any specific template name
  def self.copy_templates(mode_or_file)
    FileUtils.mkdir(settings_path) unless Dir.exist?(settings_path)
    template_path = templates_path(mode_or_file)
    return FileUtils.cp(template_path, settings_path(mode_or_file)) if File.exist?(template_path)

    files = %w[README.md secrets.yml settings.rb]
    files += %w[deployment.yml cd.sh ingress.yml service.yml] if mode_or_file == 'advanced'
    files.each do |name|
      path = settings_path(name)
      FileUtils.cp(templates_path(name), path) unless File.exist?(path)
    end
  end
end
