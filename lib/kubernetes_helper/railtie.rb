# frozen_string_literal: true

require 'kubernetes_helper'
require 'rails'

module KubernetesHelper
  class Railtie < Rails::Railtie
    railtie_name :kubernetes_helper

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/../tasks/**/*.rake").each { |f| load f }
    end
  end
end
