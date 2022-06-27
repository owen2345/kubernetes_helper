# KubernetesHelper

This gem is a helper to manage easily Kubernetes settings for GCloud (easy customization for other cloud services) where configuring and deploying a new application can be done in a couple of minutes.
Configuration and customization can be done for multiple environments and at any level which permits to deploy simple and complex applications.

## Steps
1. Install the `kubernetes_helper` gem
      ```bash
      cd my_app/
      gem install kubernetes_helper -v '~> 1.0'
      ```
      Note: Requires ruby 1.7+    

2. Generate helper settings
      ```bash
        kubernetes_helper generate_templates
      ```
      Note: `.kubernetes` folder was added. For special applications where default configurations are not enough, you can do the following: 
      - Download the required template from [lib/templates](lib/templates)
      - Put it inside `.kubernetes` folder
      - Customize based on your needs (You can add or use your custom variables from `settings.rb`)    
      Note: The local template will be used instead of the default one.

3. Install/setup the application on kubernetes    
  Open [.kubernetes/README.md](lib/templates/README.md) to see the instructions (customize the file according to your project and keep it updated in your repository)


## Settings API
### Application deployment.yml
- `deployment.name` (String): Web deployment name (Note: Underscores are not accepted). Sample: `my-app`  
- `deployment.replicas` (Integer): Quantity of replicas. Sample: `1`
- `deployment.replicas_range` (Array<min, max, cpu_percentage>, Optional): Defines the minimum and the maximum number of pods that could automatically be created when `CPUUtilizationPercentage` is above than defined. Sample: `[1, 3, 50]`
- `deployment.cloud_secret_name` (String, Optional): K8s credentials name where cloud secrets will be saved (includes permission like DB). Sample: `my-app-cloud-secret`
- `deployment.cloud_sql_instance` (String, Optional): Cloud sql instance name. Sample: `my-project:europe-west1:my-instance-name=tcp:5432` (5432 => postgres, 3306 => mysql)
- `deployment.env_vars` (Hash, optional): List of static or external env variables (Note: Not recommended for sensitive values).      
   Sample: `{ 'RAILS_ENV' => 'production' }`      
   Example for external secrets: `{ PAPERTRAIL_PORT: { name: 'common_secrets', key: 'paper_trail_port' }` will import `paper_trail_port` value from `common_secrets` yml as `PAPERTRAIL_PORT`
- `deployment.command` (String, Optional): Bash command to be used for web containers. Sample: `rails s -b 0.0.0.0`
- `deployment.liveness_path` (String, Optional): Relative path to be used for readiness and liveness checker of the web app. Sample: `/check_liveness`
- `deployment.custom_volumes` (Hash<name: path>, Optional): Custom volumes to be mounted. 
    Sample volume: `{ my_volume: { kind: 'hostPath', mount_path: '/', settings: { path: '..', type: 'Directory' } }  }`    
    Sample secret: `{ pubsub_secret: { kind: 'secret', mount_path: '/secrets/pubsub', settings: { secretName: 'my_secret_name' } } }`
- `deployment.log_container` (Boolean, default true): Permits to auto include logs container to print all logs from logs/*.log to stdout (required for papertrail using fluentd)
- `deployment.log_folder` (String, default `/app/log`): Logs to be printed from
- `deployment.app_port` (Integer, default 3000): Application port number
- `deployment.resources` (Hash, optional): Configure depending on the web app requirements. Sample: `{ cpu: { max: '1', min: '500m' }, mem: { max: '1Gi', min: '500Mi' } }`

- `deployment.cloudsql_resources` (Hash, optional): Configure depending on the app requirements. Default: `{ cpu: { max: '300m', min: '100m' }, mem: { max: '500Mi', min: '200Mi' } }`
- `deployment.logs_resources` (Hash, optional): Configure depending on the app requirements. Default: `{ cpu: { max: '200m', min: '50m' }, mem: { max: '200Mi', min: '50Mi' } }`

### Application deployment.yml for jobs or services without internet interaction (Optional)
- `deployment.job_apps[].name` (String, optional): Job deployment name (Note: Underscores are not accepted). Sample: `my-app-job`. Note: This deployment is created only if this value is present
- `deployment.job_apps[].command` (String, optional): Bash command to be used for job container. Sample: `bundle exec sidekiq`
- `deployment.job_apps[].sidekiq_alive_gem` (Boolean, default false): If true will add liveness checker settings using `sidekiq_alive_gem` (`sidekiq_alive` gem needs to be present in your Gemfile)
- `deployment.job_apps[].services` (Array, Optional): List of linux service names that are required for a healthy job container. Sample: `['sidekiq', 'cron']`. Note: This will be ignored if `sidekiq_alive_gem` was defined.     
- `deployment.job_apps[].resources` (Hash, optional): Configure depending on the job app requirements. Sample: `{ cpu: { max: '1', min: '500m' }, mem: { max: '1Gi', min: '500Mi' } }`

### Applications secrets.yml (Optional)
- `secrets.name` (String): K8s secrets name where env vars will be saved and fetched from. Sample: `my-app-secrets`

### Application service.yml (Optional)
- `service.name`: K8s service name. Sample: `my-app-service`
- `service.port_name` (String, default `http-port`): Http port name to connect between k8s ingress and service. Sample: `http-port`. Note: max 15 characters
- `service.backend_port_name` (String, default `b-port`): Web backend port name to be connected between k8s service and web deployments. Sample: `b-port`. Note: max 15 characters
- `service.type`: K8s service type. By default `NodePort`
- `service.do_certificate_id`: Digital Ocean certificate ID to be used for the loadbalancer to auto redirect http to https.       
   Note: This value can be fetched via `doctl compute certificate list`. If there are no certificates available, you can generate a new one using digital ocean dashboard -> networking -> certificates.

### Application ingress.yml (Optional)
- `ingress.name`: Name of k8s ingress for the app: Sample: `my-app-ingress`
- `ingress.ip_name` (Optional): Static ip address is not created nor assigned if empty value. Sample: `my-app-static-ip`
- `ingress.certificate_name` (Deprecated): Ssl certificate is not created nor assigned if empty value. Sample: `my-app-lets-encrypt`. Note: requires `certificate_domain` 
- `ingress.certificate_domain` (Optional): Domain name for the certificate. Sample: `myapp.com`. Note: does not support for willcard domains     
   To register multiple domains (Certificate names will be auto-generated like `mysite-com-lets-encrypt`): `certificate_domain: ['mysite.com', 'mysite.de', 'mysite.uk']`

- `cloud.name` (String, optional): Cloud service name: `gcloud | digital_ocean`. Default `gcloud`.  

### Application CD (continuous deployment)
- `continuous_deployment.image_name` (String): Partial docker image url. Sample: `gcr.io/my-account/my_app_name`
- `continuous_deployment.image_tag` (String, default 'latest'): Image tag to be used for this application
- `continuous_deployment.project_name`: Cloud project name. Sample: `my-project-name`
- `continuous_deployment.cluster_name`: Cluster cluster name. Sample: `my-cluster-name`
- `continuous_deployment.cluster_region`: Cluster region name. Sample: `europe-west4-a`
- `continuous_deployment.docker_build_cmd` (deprecated): Docker command to build the corresponding image. Sample: `build --target production -f Dockerfile `
- `continuous_deployment.docker_cmd` (String): Docker command to build the corresponding image.      
  Simple docker image: `docker build -f Dockerfile -t $DEPLOY_NAME .`    
  Docker image with target: `docker build --target production -f Dockerfile -t $DEPLOY_NAME .`        
- `continuous_deployment.update_deployment` (Boolean, default: false): If true permits to re-generate and update the k8s deployment(s) before applying the new version (new docker image)

### Gem templating partials
- `_container_extra_settings.yml` Partial template to add custom container settings. Receives `pod` as local variable (`web` | `job` | `cloudsql` | `logs`) and `pod_name`. Sample:
  ```yaml
               <% if locals[:pod] == 'job' %>
               resources:
                 requests:
                   cpu: 50m
                   memory: 256Mi
                 limits:
                   cpu: 500m
                   memory: 1Gi
               <% end %>
  ``` 
- `_custom_containers.yml` Partial template to add extra containers (Receives `pod` as local variable: `web` | `job`) and `pod_name`. Sample:
```yaml
           <% if locals[:pod] == 'job' %>
           - name: scraper
             image: owencio/easy_scraper
             ...
           <% end %>
```
- `_cd_apply_images.sh` Partial template to customize the process to apply the new version (new docker image)

### Gem templating
When performing a command or script, the setting variables are replaced based on `DEPLOY_ENV`. 
All these setting variable values are configured in `.kubernetes/settings.rb` which defines the values based on `DEPLOY_ENV`.     
These setting variables use [erb](https://github.com/ruby/erb) template gem to define variable replacement and conditional blocks, and so on.
Note: Setting variable values are referenced as an object format instead of a hash format for simplicity.
  

### Sample
https://owen2345.github.io/kubernetes_helper/


## API
- Run any kubernetes document    
  `DEPLOY_ENV=<env name> kubernetes_helper run_deployment "<document name>" "<bash command>"`    
  Evaluates the kubernetes document with the following details:
  - Supports for `- documents` to include multiple documents in a file and share yml variables between them (Sample: `lib/templates/deployment.yml#1`)
  - Replaces all setting values based on `DEPLOY_ENV`
  - Supports for secrets auto importer using `import_secrets: ['secrets.yml', '<%=secrets.name%>']` (Sample: `lib/templates/deployment.yml#29`)
  - Supports for sub templates by `include_template 'template_name.yml.erb', { my_local_var: 10 }`    
  Sample: `DEPLOY_ENV=beta kubernetes_helper run_deployment "deployment.yml" "kubectl create"`
   
- Run kubernetes commands    
  `DEPLOY_ENV=<env name> rake kubernetes_helper:run_command "<bash or k8s commands>"`           
  Replaces all setting variables inside command based on `DEPLOY_ENV` and performs it as a normal bash command.             
  Sample: `DEPLOY_ENV=beta rake kubernetes_helper:run_command "gcloud compute addresses create \#{ingress.ip_name} --global"'`    
  
- Run kubernetes bash scripts     
  `DEPLOY_ENV=<env name> kubernetes_helper run_script "<script name>"`    
  Performs the script name located inside `.kubernetes` folder or kubernetes_helper template as the second option.
  All setting variables inside the script will be replaced based on `DEPLOY_ENV`.      
  Sample: `DEPLOY_ENV=beta kubernetes_helper run_script "cd.sh"`

- Generate templates    
  `DEPLOY_ENV=<env name> kubernetes_helper generate_templates "<mode_or_template_name>"`     
  Copy files based on mode (`basic|advanced`) or a specific file from templates.     
  Sample: `DEPLOY_ENV=beta kubernetes_helper generate_templates "basic"`    
  Sample: `DEPLOY_ENV=beta kubernetes_helper generate_templates "ingress.yml"`    

When performing a script it looks first for file inside .kubernetes folder, if not exist, 
it looks for the file inside kubernetes_helper template folder.

## TODO
- Add one_step_configuration.sh
- Change `include_template` into `ERB render partial`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kubernetes_helper. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/kubernetes_helper/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the KubernetesHelper project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/kubernetes_helper/blob/master/CODE_OF_CONDUCT.md).
