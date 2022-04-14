# Download and install doctl
if [ -z "$(which doctl)" ]; then
  wget https://github.com/digitalocean/doctl/releases/download/v1.72.0/doctl-1.72.0-linux-amd64.tar.gz
  tar xf ~/doctl-1.72.0-linux-amd64.tar.gz
  sudo mv ~/doctl /usr/local/bin
fi

if [ ! -z "$KB_AUTH_TOKEN" ]
then
  doctl auth init --access-token $KB_AUTH_TOKEN
fi

## Build and push containers
echo "****** building image..."
<% if continuous_deployment.docker_cmd %>
  <%= continuous_deployment.docker_cmd %>
<% else %>
  docker <%=continuous_deployment.docker_build_cmd || 'build -f Dockerfile'%> -t $DEPLOY_NAME .
<% end %>
docker push $DEPLOY_NAME

echo "****** tagging image $DEPLOY_NAME as $LATEST_NAME"
docker tag $DEPLOY_NAME $LATEST_NAME
docker push $LATEST_NAME
