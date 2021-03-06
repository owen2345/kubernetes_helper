require 'bundler/setup'
require 'kubernetes_helper'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    path = File.join(__dir__, '../lib/templates')
    allow(KubernetesHelper).to receive(:settings_path) do |name = nil|
      name ? File.join(path, name) : path
    end
  end
end
