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
  def self.load_settings
    config_file = File.join(settings_path, 'settings.rb')
    load config_file
    settings
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

  # @param mode (basic, advanced)
  def self.copy_templates(mode)
    FileUtils.mkdir(settings_path) unless Dir.exist?(settings_path)
    files = %w[README.md secrets.yml settings.rb]
    files += %w[deployment.yml cd.sh ingress.yml service.yml] if mode == 'advanced'
    files.each do |name|
      path = settings_path(name)
      FileUtils.cp(templates_path(name), path) unless File.exist?(path)
    end
  end
end
