# Kubernetes app configuration

## Configure a new application environment
- Create the project on Gcloud
- Set the project where to work on
    `gcloud config set project my-project`
    
- Create the cluster (Only if not exist)
    `gcloud container clusters create my-cluster`
    `# gcloud container clusters list --region europe-west4-a # to list clusters`
  
- Use the cluster/project as default
    `gcloud container clusters get-credentials my-cluster --zone europe-west4-a`
  
- Install helper for the next commands
  `gem install kubernetes_helper`
  
- Verify or update k8s settings in kubernetes/settings.rb
    
- Create the public ip address
    ```bash
    DEPLOY_ENV=beta kubernetes_helper run_command "gcloud compute addresses create #{ingress.ip_name} --global"
    # gcloud compute addresses list # to list static ips generated 
    ```
    
- Register env vars (values must be encrypted using base64) 
    Open and register secret values in `kubernetes/secrets.yml`     
    Note: Enter base64 encoded values
    ```bash
    DEPLOY_ENV=beta kubernetes_helper run_yml 'secrets.yml' 'kubectl create'
    # kubectl get secrets # to list all secrets registered
    ```
    
- Create service to connect pods and ingress
    ```bash
    DEPLOY_ENV=beta kubernetes_helper run_yml 'service.yml' 'kubectl create'
    # kubectl get services # to list all registered services
    ```
    
- Register shared cloudsql proxy configuration (only if not exists)
    ```bash
    DEPLOY_ENV=beta kubernetes_helper run_command "kubectl create secret generic #{deployment.cloud_secret_name} --from-file=credentials.json=<path-to-downloaded/credentials.json>"
    ```
    
- Register the ssl certificates (Using lets encrypt)
    ```bash
    DEPLOY_ENV=beta kubernetes_helper run_yml 'certificate.yml' 'kubectl create'
    # kubectl get ManagedCertificate # to list all certificates
  ```
  Note: Wildcard domains are not supported
    
- Create ingress to register hosts, certificates and connect with service
    ```bash
    DEPLOY_ENV=beta kubernetes_helper run_yml 'ingress.yml' 'kubectl create'
    # kubectl get ingress # to list all registered ingresses
    ```
    
- Create deployment (match Dockerfile exposed port with containerPort, register env vars from secrets.yml, indicate the correct container image)
    ```bash
    DEPLOY_ENV=beta kubernetes_helper run_yml 'deployment.yml' 'kubectl create'
    # kubectl get deployment # to list deployments
    ```

## Apply any k8s setting changes
- Secrets
  - Enter your values base64 encoded and save it.
    `kubectl edit secret my-secret-name`        
  - Delete all pods using this secret
    `kubectl delete pod my-pod-name`   
    See https://medium.com/devops-dudes/how-to-propagate-a-change-in-kubernetes-secrets-by-restarting-dependent-pods-b71231827656
  
- Other settings
  ```bash
    DEPLOY_ENV=beta kubernetes_helper run_yml 'deployment.yml' 'kubectl apply'
  ```

## Configure continuous deployment for github actions
* Go to github repository settings
* Register a new secret variable with content downloaded from https://console.cloud.google.com/iam-admin/serviceaccounts  (Make sure to attach a Storage Admin role to the service account)
  ```bash
    beta: BETA_CLOUD_TOKEN=<secret content here>
    production: PROD_CLOUD_TOKEN=<secret content here>
  ```
  Reference: https://semaphoreci.com/docs/docker/continuous-delivery-google-container-registry.html
  
* Add action to run deployment:
  ```bash
    DEPLOY_ENV=beta kubernetes_helper run_DEPLOYMENT 'cd_gcloud.sh'
  ```  