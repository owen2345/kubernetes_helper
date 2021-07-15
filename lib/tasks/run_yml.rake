# frozen_string_literal: true

namespace :kubernetes_helper do
  desc 'Parses kubernetes yml files (supporting multiple documents, Config variables replacement, include secrets). Sample: '\
        'DEPLOY_ENV=beta rake kubernetes_helper:run_deployment "deployment.yml" "kubectl create"'
  task :run_yml do
    yml_path = KubernetesHelper.settings_path(ARGV[1])
    command = ARGV[2]
    output_path = KubernetesHelper.settings_path('tmp_result.yml')
    KubernetesHelper::Core
      .new(ENV['DEPLOY_ENV'])
      .parse_yml_file(yml_path, output_path)
    KubernetesHelper.run_cmd("#{command} -f #{output_path}")
  end
end
