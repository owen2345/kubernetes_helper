# Download and install doctl
if [ -z "$(which doctl)" ]; then
  sudo snap install doctl
fi

if [ ! -z "$KB_AUTH_TOKEN" ]
then
  doctl auth init --access-token $KB_AUTH_TOKEN
fi

## Build and push containers
echo "****** building image..."
eval $DOCKER_BUILD_CMD
docker push $DEPLOY_NAME

echo "****** tagging image $DEPLOY_NAME as $LATEST_NAME"
docker tag $DEPLOY_NAME $LATEST_NAME
docker push $LATEST_NAME
