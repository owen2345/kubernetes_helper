# Download and install doctl
if [ -z "$(which doctl)" ]; then
  sudo snap install doctl
  sudo snap connect doctl:dot-docker
fi

if [ ! -z "$KB_AUTH_TOKEN" ]
then
  doctl auth init --access-token $KB_AUTH_TOKEN
  doctl registry login --access-token $KB_AUTH_TOKEN
fi

## Build and push containers
echo "****** building image...$DOCKER_BUILD_CMD and push via: docker push $DEPLOY_NAME"
eval $DOCKER_BUILD_CMD
docker push $DEPLOY_NAME

echo "****** tagging image $DEPLOY_NAME as $LATEST_NAME"
docker tag $DEPLOY_NAME $LATEST_NAME
docker push $LATEST_NAME
