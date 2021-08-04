#!/bin/bash
set -e
# expected ENV VAR "KB_AUTH_TOKEN"

SCRIPT_DIR=`dirname "$(realpath -s "$0")"` # app_dir/.kubernetes/
cd "$SCRIPT_DIR/../" # project directory

DEPLOYMENTS="<%=[deployment.name, deployment.job_name].join(',')%>"
IMAGE_NAME="<%=continuous_deployment.image_name%>"
CLUSTER_NAME="<%=continuous_deployment.cluster_name%>"
PROJECT_NAME="<%=continuous_deployment.project_name%>"
CLUSTER_REGION="<%=continuous_deployment.cluster_region%>"
DOCKER_BUILD_CMD="<%=continuous_deployment.docker_build_cmd || 'build -f Dockerfile'%>"

CI_COMMIT_SHA=$(git rev-parse --verify HEAD)
DEPLOY_NAME="${IMAGE_NAME}:${CI_COMMIT_SHA}"
LATEST_NAME="${IMAGE_NAME}:latest"
AUTH_PATH="$SCRIPT_DIR/k8s-auth-token.json"

rm -f -- $AUTH_PATH
echo $KB_AUTH_TOKEN >> $AUTH_PATH

## ***** GOOGLE CONNECTOR
# Download and install Google Cloud SDK
if [ -z "$(which gcloud)" ]; then
  export CLOUDSDK_CORE_DISABLE_PROMPTS=1; curl https://sdk.cloud.google.com | bash && source /home/runner/google-cloud-sdk/path.bash.inc &&  gcloud --quiet components update kubectl
fi

# Connect to cluster
gcloud auth activate-service-account --key-file $AUTH_PATH --project $PROJECT_NAME
gcloud docker --authorize-only --project $PROJECT_NAME
gcloud container clusters get-credentials $CLUSTER_NAME --region $CLUSTER_REGION
## ***** END GOOGLE CONNECTOR


## Build and push containers
docker $DOCKER_BUILD_CMD -t $DEPLOY_NAME .
docker tag $DEPLOY_NAME $LATEST_NAME
docker push $DEPLOY_NAME
docker push $LATEST_NAME

## Apply deployments
IFS=',' read -r -a deployments <<< "$DEPLOYMENTS"
for deployment in "${deployments[@]}"; do
  [ -z "$deployment" ] && continue # if empty value

  kubectl set image deployment/$deployment $deployment=$DEPLOY_NAME
  [ "$deployment" = "${deployments[0]}" ] && kubectl rollout status deployment/$deployment || true
done
