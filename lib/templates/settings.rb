# frozen_string_literal: true

is_beta = ENV['DEPLOY_ENV'] == 'beta'
app_name = is_beta ? 'my_beta_app' : 'my_app'
settings = {
  deployment: {
    name: app_name,
    replicas: is_beta ? 1 : 2,
    cloud_secret_name: "#{is_beta ? 'beta' : 'production'}-cloud-secret",
    cloud_sql_instance: 'xxx:xxx:xxx=tcp:5432', # 5432 => postgres, 3306 => mysql
    env_vars: {}, # Sample: { 'CUSTOM_VAR' => 'value' }
    # liveness_path: '/check_liveness', # nil if not exist
    # job_name: "#{app_name}-job", # enable if there is any background service
    # job_command: 'bundle exec sidekiq -C config/sidekiq.yml',
    # job_services: ['sidekiq', 'cron'] # list of linux services needed.
  },
  ingress: {
    name: "#{app_name}-ingress",
    ip_name: "#{app_name}-static-ip", # nil if static ip is not necessary
    certificate_name: "#{app_name}-lets-encrypt", # nil if ssl is not required
    domain_name: is_beta ? 'beta.myapp.com' : 'myapp.com' # nil if domain is not required
  },
  continuous_deployment: {
    image_name: "gcr.io/my-account/#{app_name}",
    project_name: 'my-project-name',
    cluster_name: 'my-cluster-name',
    cluster_region: 'europe-west4-a'
  },
  secrets: {
    name: "#{app_name}-secrets"
  },
  service: {
    name: app_name,
    port_name: 'http-port', # max 15 characters
    backend_port_name: 'b-port', # max 15 characters
    config_name: "#{app_name}-backend-config"
  }
}

KubernetesHelper.settings(settings)