# frozen_string_literal: true

is_production = ENV['DEPLOY_ENV'] == 'production'
app_name = is_production ? 'my-app' : 'my-beta-app' # underscore not accepted
settings = {
  deployment: {
    name: app_name,
    replicas: is_production ? 2 : 1,
    replicas_range: nil, # [min, max] or nil to ignore, sample: is_production ? [1, 2] : nil
    cloud_secret_name: "#{is_production ? 'production' : 'beta'}-cloud-secret",
    cloud_sql_instance: 'xxx:xxx:xxx=tcp:5432', # 5432 => postgres, 3306 => mysql
    env_vars: {}, # Sample: { 'CUSTOM_VAR' => 'value' }
    # command: '', # custom container command (default empty to be managed by Dockerfile)
    # liveness_path: '/check_liveness', # nil if not exist
    # job_name: "#{app_name}-job", # enable if there is any background service
    # job_command: 'bundle exec sidekiq -C config/sidekiq.yml',
    # job_services: ['sidekiq', 'cron'] # list of linux services needed.
    # custom_volumes: { my_volume: { kind: 'hostPath', mount_path: '/', settings: { path: '..', type: 'Directory' } }  }
  },
  secrets: {
    name: "#{app_name}-secrets"
  },
  service: {
    name: app_name,
  },
  ingress: {
    name: "#{app_name}-ingress",
    ip_name: "#{app_name}-static-ip", # nil if static ip is not necessary
    certificate_name: "#{app_name}-lets-encrypt", # nil if ssl is not required
    certificate_domain: is_production ? 'myapp.com' : 'beta.myapp.com' # nil if domain is not required
  },
  continuous_deployment: {
    image_name: "gcr.io/my-account/#{app_name}",
    image_tag: 'latest',
    project_name: 'my-project-name',
    cluster_name: 'my-cluster-name',
    cluster_region: 'europe-west4-a',
    docker_cmd: 'docker build -f Dockerfile -t $DEPLOY_NAME .', # using target: 'docker build --target production -f Dockerfile -t $DEPLOY_NAME .'
    update_deployment: false # permits to reload secrets and re-generate/update deployment yaml
  },
}

KubernetesHelper.settings(settings)
