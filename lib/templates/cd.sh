#!/bin/bash
set -e
# expected ENV VAR "KB_AUTH_TOKEN"

SCRIPT_DIR=`dirname "$(realpath -s "$0")"` # app_dir/.kubernetes/
cd "$SCRIPT_DIR/../" # project directory

DEPLOYMENTS="<%=(deployment.job_apps.map { |a| a[:name] } + [deployment.name]).join(',')%>"
IMAGE_NAME="<%=continuous_deployment.image_name%>"
CLUSTER_NAME="<%=continuous_deployment.cluster_name%>"
PROJECT_NAME="<%=continuous_deployment.project_name%>"
CLUSTER_REGION="<%=continuous_deployment.cluster_region%>"

CI_COMMIT_SHA=$(git rev-parse --verify HEAD || :)
CI_COMMIT_SHA=${CI_COMMIT_SHA:-$(date +%s) }
DEPLOY_NAME="${IMAGE_NAME}:${CI_COMMIT_SHA}"
LATEST_NAME="${IMAGE_NAME}:<%= continuous_deployment.image_tag || 'latest' %>"

<%= include_template "_cd_google.sh" if continuous_deployment.image_name.include?('gcr.io/') %>
<%= include_template "_cd_digital.sh" if continuous_deployment.image_name.include?('digitalocean.com/') %>

## Apply deployments
IFS=',' read -r -a deployments <<< "$DEPLOYMENTS"
for deployment in "${deployments[@]}"; do
  [ -z "$deployment" ] && continue # if empty value

  <%= include_template "_cd_apply_images.sh" %>
done

## Update new secrets defined in secrets.yml as ENV vars for deployments
<% if continuous_deployment.update_deployment %>
  kubernetes_helper run_yml 'deployment.yml' 'kubectl apply'
<% end %>