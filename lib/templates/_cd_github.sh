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
