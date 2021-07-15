# frozen_string_literal: true

beta_app_name = 'my_beta_app'
app_name = 'my_beta_app'
settings = {
  beta: {
    service: {
      name: beta_app_name,
      port_name: 'http-port', # max 15 characters
      backend_port_name: 'b-port', # max 15 characters
      config_name: "#{beta_app_name}-backend-config"
    },
    deployment: {
      name: beta_app_name,
      replicas: 1,
      rails_env: 'beta',
      cloud_secret_name: 'beta-cloud-secret',
      cloud_sql_instance: 'xxx:xxx:xxx'
    },
    secrets: {
      name: "#{beta_app_name}-secrets"
    },
    certificate: {
      name: "#{beta_app_name}-lets-encrypt",
      domain_name: 'beta.myapp.com'
    },
    ingress: {
      name: "#{beta_app_name}-ingress",
      ip_name: "#{beta_app_name}-static-ip"
    },
    continuous_deployment: {
      auth_token: ENV['BETA_CLOUD_TOKEN'],
      deployments: beta_app_name, # supports for multiple (comma separated, sample: 'my_app,my_app_sidekiq')
      image_name: "gcr.io/my-account/#{beta_app_name}",
      cluster_name: 'my-cluster-name',
      project_name: 'my-project-name'
    }
  },

  # Production settings
  production: {
    service: {
      name: "#{app_name}-service",
      port_name: 'http-port', # max 15 characters
      backend_port_name: 'b-port', # max 15 characters
      config_name: "#{app_name}-backend-config"
    },
    deployment: {
      name: app_name,
      replicas: 2,
      rails_env: 'production',
      cloud_secret_name: 'cloud-secret',
      cloud_sql_instance: 'xxx:xxx:xxx'
    },
    secrets: {
      name: "#{app_name}-secrets"
    },
    certificate: {
      name: "#{app_name}-lets-encrypt",
      domain_name: 'myapp.com'
    },
    ingress: {
      name: "#{app_name}-ingress",
      ip_name: "#{app_name}-static-ip"
    },
    continuous_deployment: {
      auth_token: ENV['PROD_CLOUD_TOKEN'],
      deployments: app_name,
      image_name: "gcr.io/my-account/#{app_name}",
      cluster_name: 'my-cluster-name',
      project_name: 'my-project-name'
    }
  }
}

KubernetesHelper.settings(settings)
