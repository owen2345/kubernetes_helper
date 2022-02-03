# KubernetesHelper

This gem is a helper to manage easily Kubernetes settings for GCloud (easy customization for other cloud services) where configuring and deploying a new application can be done in a couple of minutes.
Configuration and customization can be done for multiple environments and at any level which permits to deploy simple and complex applications.

## Installation
```bash
cd my_app/
gem install kubernetes_helper -v '~> 1.0'
kubernetes_helper generate_templates
```
Note: Requires ruby 1.7+     

## Configuration
- Edit `.kubernetes/settings.rb` and enter or replace all settings with the valid ones
- For special applications where default configurations are not enough, you can do the following: 
    - Download the corresponding template from [lib/templates](lib/templates)
    - Put it inside `.kubernetes` folder
    - Customize based on your needs (You can add or use your custom variables from `settings.rb`)    
    Note: The local template will be used instead of the default.

## Deployment
Once you generated the basic templates, it comes with the corresponding [readme.md](/lib/templates/README.md) which includes all the steps to deploy your application.

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

## Settings API
Below settings are used when running Continuous Deployment
- `continuous_deployment.image_name` (String, Optional): Partial docker image url where `:latest` will be automatically added. Sample: `gcr.io/my-account/my_app_name`
- `continuous_deployment.image` (String, Optional, is mandatory if `image_name` is empty): Full docker image url. Sample: `gcr.io/my-account/my_app_name:latest`
- `continuous_deployment.project_name`: Cloud project name. Sample: `my-project-name`
- `continuous_deployment.cluster_name`: Cluster cluster name. Sample: `my-cluster-name`
- `continuous_deployment.cluster_region`: Cluster region name. Sample: `europe-west4-a`
- `continuous_deployment.docker_build_cmd`: Docker command to build the corresponding image. Sample: `build --target production -f Dockerfile `
- `continuous_deployment.update_deployment` (Boolean, default: false): If true permits to re-generate and update the k8s deployment(s) before applying the new version (new docker image) 

Below settings are used when configuring the application in the k8s environment
- `deployment.name` (String): Web deployment name (Note: Underscores are not accepted). Sample: `my-app`  
- `deployment.replicas` (Integer): Quantity of replicas. Sample: `1`
- `deployment.replicas_range` (Array<min, max, cpu_percentage>, Optional): Defines the minimum and the maximum number of pods that could automatically be created when `CPUUtilizationPercentage` is above than defined. Sample: `[1, 3, 50]`
- `deployment.cloud_secret_name` (String, Optional): K8s credentials name where cloud secrets will be saved (includes permission like DB). Sample: `my-app-cloud-secret`
- `deployment.cloud_sql_instance` (String, Optional): Cloud sql instance name. Sample: `my-project:europe-west1:my-instance-name=tcp:5432` (5432 => postgres, 3306 => mysql)
- `deployment.env_vars` (Hash, optional): List of static env variables (Note: Not recommended for sensitive values). Sample: `{ 'RAILS_ENV' => 'production' }`
- `deployment.command` (String, Optional): Bash command to be used for web containers. Sample: `rails s -b 0.0.0.0`
- `deployment.liveness_path` (String, Optional): Relative path to be used for readiness and liveness checker of the web app. Sample: `/check_liveness`
- `deployment.custom_volumes` (Hash<name: path>, Optional): Custom volumes to be mounted. Sample: `{ my_volume: { kind: 'hostPath', mount_path: '/', settings: { path: '..', type: 'Directory' } }  }`

- `deployment.job_name` (String, optional): Job deployment name (Note: Underscores are not accepted). Sample: `my-app-job`. Note: This deployment is created only if this value is present
- `deployment.job_command` (String, optional): Bash command to be used for job container. Sample: `bundle exec sidekiq`
- `deployment.job_sidekiq_alive_gem` (Boolean, default false): If true will add liveness checker settings using `sidekiq_alive_gem` (`sidekiq_alive` gem needs to be present in your Gemfile)
- `deployment.job_services` (Array, Optional, only `job_sidekiq_alive_gem` or `job_services` is allowed): List of linux service names that are required for a healthy job container. Sample: `['sidekiq', 'cron']` 


- `secrets.name` (String): K8s secrets name where env vars will be saved and fetched from. Sample: `my-app-secrets`

- `service.name`: K8s service name. Sample: `my-app-service`
- `service.port_name`: Http port name to connect between k8s ingress and service. Sample: `http-port`. Note: max 15 characters
- `service.backend_port_name` (String): Web backend port name to be connected between k8s service and web deployments. Sample: `b-port`. Note: max 15 characters

- `ingress.name`: Name of k8s ingress for the app: Sample: `my-app-ingress`
- `ingress.ip_name` (Optional): Static ip address is not created nor assigned if empty value. Sample: `my-app-static-ip`
- `ingress.certificate_name` (Optional): Ssl certificate is not created nor assigned if empty value. Sample: `my-app-lets-encrypt`. Note: requires `certificate_domain` 
- `ingress.certificate_domain` (Optional): Domain name for the certificate. Sample: `myapp.com`. Note: does not support for willcard domains

### Partials
- `_container_extra_settings.yml` Partial template to add custom container settings. Receives `pod` as local variable (`web` | `job` | `cloudsql` | `logs`). Sample:
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
- `_custom_containers.yml` Partial template to add extra containers (Receives `pod` as local variable: `web` | `job`). Sample:
```yaml
           <% if locals[:pod] == 'job' %>
           - name: scraper
             image: owencio/easy_scraper
             ...
           <% end %>
```
- `_cd_apply_images.sh` Partial template to customize the process to apply the new version (new docker image)

## Templating
When performing a command or script, the setting variables are replaced based on `DEPLOY_ENV`. 
All these setting variable values are configured in `.kubernetes/settings.rb` which defines the values based on `DEPLOY_ENV`.     
These setting variables use [erb](https://github.com/ruby/erb) template gem to define variable replacement and conditional blocks, and so on.
Note: Setting variable values are referenced as an object format instead of a hash format for simplicity.
  

## Sample
https://owen2345.github.io/kubernetes_helper/

## TODO
- Add one_step_configuration.sh

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kubernetes_helper. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/kubernetes_helper/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the KubernetesHelper project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/kubernetes_helper/blob/master/CODE_OF_CONDUCT.md).
