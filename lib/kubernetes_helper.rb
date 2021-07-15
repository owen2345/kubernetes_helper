# frozen_string_literal: true

require 'kubernetes_helper/core'
require 'kubernetes_helper/railtie' if defined?(Rails)

module KubernetesHelper
  class Error < StandardError; end
  FOLDER_NAME = 'kubernetes'

  def self.settings(settings = nil)
    @settings = settings if settings
    @settings
  end

  # @param env_name (String)
  # @return [Hash]
  def self.load_settings(env_name)
    config_file = File.join(settings_path, 'settings.rb')
    load config_file
    settings[env_name.to_sym]
  end

  def self.settings_path(file_name = nil)
    path = File.join(Dir.pwd, FOLDER_NAME)
    path = File.join(path, file_name) if file_name
    path
  end

  def self.run_cmd(cmd)
    res = Kernel.system cmd
    Kernel.abort("::::::::CD: failed running command: #{cmd} ==> #{caller}") if res != true
  end
end
