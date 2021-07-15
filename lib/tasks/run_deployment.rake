# frozen_string_literal: true

namespace :kubernetes_helper do
  desc 'Run the deployment script. Sample: DEPLOY_ENV=beta rake kubernetes_helper:run_deployment "cd_gcloud.sh"'
  task :run_deployment do
    ARGV.each { |a| task a.to_sym do; end }
    script_path = KubernetesHelper.settings_path(ARGV[1])
    KubernetesHelper::Core.new(ENV['DEPLOY_ENV']).run_cd_script(script_path)
  end
end


