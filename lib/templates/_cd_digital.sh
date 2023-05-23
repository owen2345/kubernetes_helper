if [ -z "$(which doctl)" ]; then
  wget https://github.com/digitalocean/doctl/releases/download/v1.72.0/doctl-1.72.0-linux-amd64.tar.gz
  tar xf ./doctl-1.72.0-linux-amd64.tar.gz
  mv ./doctl /usr/local/bin
fi

## login doctl
doctl auth init --access-token $KB_AUTH_TOKEN
doctl registry login --access-token $KB_AUTH_TOKEN --expiry-seconds 1200

## Build and push containers
echo "****** building image...$DOCKER_BUILD_CMD"
eval $DOCKER_BUILD_CMD

echo "****** pushing image...$DEPLOY_NAME"
docker push $DEPLOY_NAME

echo "****** tagging image... $DEPLOY_NAME as $LATEST_NAME"
docker tag $DEPLOY_NAME $LATEST_NAME
docker push $LATEST_NAME

## enable registry to update deployment
<% if continuous_deployment.cluster_name %>
doctl kubernetes cluster kubeconfig save --expiry-seconds 600 <%= continuous_deployment.cluster_name %>
<% end %>