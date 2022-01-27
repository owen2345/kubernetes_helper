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
