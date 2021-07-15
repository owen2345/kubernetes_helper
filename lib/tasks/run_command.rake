# frozen_string_literal: true

namespace :kubernetes_helper do
  desc 'Parse variables and run provided command.
        Sample: DEPLOY_ENV=beta rake kubernetes_helper:run_command
                "gcloud compute addresses create \#{ingress.ip_name} --global"'
  task :run_command do
    KubernetesHelper::Core.new(ENV['DEPLOY_ENV']).run_command(ARGV[1])
  end
end
