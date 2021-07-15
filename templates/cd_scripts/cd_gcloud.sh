#!/bin/sh

# expected vars: AUTH_TOKEN, DEPLOYMENTS, IMAGE_NAME, CLUSTER_NAME, PROJECT_NAME

CI_COMMIT_SHA=$(git rev-parse --verify HEAD)
DEPLOY_NAME="${IMAGE_NAME}:${CI_COMMIT_SHA}"
LATEST_NAME="${IMAGE_NAME}:latest"
GOOGLE_AUTH_PATH="./google-auth.json"
echo "$AUTH_TOKEN" > "$GOOGLE_AUTH_PATH"

## Download and install Google Cloud SDK
if ! gcloud --version &> /dev/null; then
  export CLOUDSDK_CORE_DISABLE_PROMPTS=1; curl https://sdk.cloud.google.com | bash && source /home/runner/google-cloud-sdk/path.bash.inc &&  gcloud --quiet components update kubectl
fi

# Connect to cluster
gcloud auth activate-service-account --key-file $GOOGLE_AUTH_PATH --project $PROJECT_NAME
gcloud docker --authorize-only --project $PROJECT_NAME
gcloud container clusters get-credentials $CLUSTER_NAME --region $KUBE_REGION

## Build and push containers
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
docker build -f "$SCRIPT_DIR/../Dockerfile" -t $DEPLOY_NAME .
docker tag $DEPLOY_NAME $LATEST_NAME
docker push $DEPLOY_NAME
docker push $LATEST_NAME

## Apply deployments
counter=0
IFS=',' read -r -a deployments <<< "$DEPLOYMENTS"
for deployment in "${deployments[@]}"; do
  echo "::::::::CD: Deploying $deployment"
  kubectl set image deployment/$deployment $deployment=$DEPLOY_NAME
  if [[ $counter -eq 0 ]]; then
    echo "::::::::CD: waiting for possible migrations in $deployment"
    kubectl rollout status deployment/$deployment
  fi
  counter=$((counter+1))
done
echo "::::::::CD: Deployment finished"
