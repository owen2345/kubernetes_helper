# frozen_string_literal: true

beta_app_name = 'my_beta_app'
app_name = 'my_beta_app'
settings = {
  beta: {
    deployment: {
      name: beta_app_name,
      replicas: 1,
      cloud_secret_name: 'beta-cloud-secret',
      cloud_sql_instance: 'xxx:xxx:xxx=tcp:5432', # 5432 => postgres, 3306 => mysql
      env_vars: {}, # Sample: { 'RAILS_ENV' => 'beta', 'CUSTOM_VAR' => 'value' }
      liveness_path: nil, # nil if not exist
      job_name: nil, # nil if not required
      job_command: nil,
      job_services: [] # list of linux services needed. Sample: ['sidekiq', 'cron']
    },
    ingress: {
      name: "#{beta_app_name}-ingress",
      ip_name: "#{beta_app_name}-static-ip", # nil if static ip is not necessary
      certificate_name: "#{beta_app_name}-lets-encrypt",
      domain_name: 'beta.myapp.com' # nil if domain is not necessary (Wildcard domains are not supported)
    },
    continuous_deployment: {
      deployments: beta_app_name, # supports for multiple (comma separated, sample: 'my_app,my_app_sidekiq')
      image_name: "gcr.io/my-account/#{beta_app_name}",
      project_name: 'my-project-name',
      cluster_name: 'my-cluster-name',
      cluster_region: 'europe-west4-a'
    },
    secrets: {
      name: "#{beta_app_name}-secrets"
    },
    service: {
      name: beta_app_name,
      port_name: 'http-port', # max 15 characters
      backend_port_name: 'b-port', # max 15 characters
      config_name: "#{beta_app_name}-backend-config"
    }
  },

  # Production settings
  production: {
    deployment: {
      name: app_name,
      replicas: 2,
      cloud_secret_name: 'cloud-secret',
      cloud_sql_instance: 'xxx:xxx:xxx=tcp:5432',
      env_vars: {},
      liveness_path: '/health_check',
      job_name: nil,
      job_command: nil,
      job_services: []
    },
    ingress: {
      name: "#{app_name}-ingress",
      ip_name: "#{app_name}-static-ip",
      certificate_name: "#{app_name}-lets-encrypt",
      domain_name: 'myapp.com'
    },
    continuous_deployment: {
      deployments: app_name,
      image_name: "gcr.io/my-account/#{app_name}",
      project_name: 'my-project-name',
      cluster_name: 'my-cluster-name',
      cluster_region: 'europe-west4-a'
    },
    secrets: {
      name: "#{app_name}-secrets"
    },
    service: {
      name: "#{app_name}-service",
      port_name: 'http-port', # max 15 characters
      backend_port_name: 'b-port', # max 15 characters
      config_name: "#{app_name}-backend-config"
    }
  }
}

KubernetesHelper.settings(settings)
