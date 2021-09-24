  kubectl set image deployment/$deployment $deployment=$DEPLOY_NAME
  [ "$deployment" = "${deployments[0]}" ] && kubectl rollout status deployment/$deployment || true