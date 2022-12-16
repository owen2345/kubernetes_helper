if [ ! -z "$KB_AUTH_TOKEN" ]
then
  AUTH_PATH="$SCRIPT_DIR/k8s-auth-token.json"
  rm -f -- $AUTH_PATH
  echo $KB_AUTH_TOKEN >> $AUTH_PATH

  ## ***** GOOGLE CONNECTOR
  # Download and install Google Cloud SDK
  if [ -z "$(which gcloud)" ]; then
    export CLOUDSDK_CORE_DISABLE_PROMPTS=1; curl https://sdk.cloud.google.com | bash && source /home/runner/google-cloud-sdk/path.bash.inc &&  gcloud --quiet components update kubectl
  fi

  # Connect to cluster
  export USE_GKE_GCLOUD_AUTH_PLUGIN=True
  gcloud components install gke-gcloud-auth-plugin
  gcloud auth activate-service-account --key-file $AUTH_PATH --project $PROJECT_NAME
  gcloud docker --authorize-only --project $PROJECT_NAME
  gcloud container clusters get-credentials $CLUSTER_NAME --region $CLUSTER_REGION
  ## ***** END GOOGLE CONNECTOR
fi


ALREADY_DEPLOYED="$(gcloud container images list-tags --format='get(tags)' $IMAGE_NAME | grep $CI_COMMIT_SHA || :;)"
if [ -z $ALREADY_DEPLOYED ]
then
  ## Build and push containers
  echo "****** image not created yet, building image..."
  eval $DOCKER_BUILD_CMD
  docker push $DEPLOY_NAME
else
  echo "****** image was already created: $ALREADY_DEPLOYED"
fi

echo "****** tagging image $DEPLOY_NAME as $LATEST_NAME"
gcloud container images add-tag --quiet $DEPLOY_NAME $LATEST_NAME