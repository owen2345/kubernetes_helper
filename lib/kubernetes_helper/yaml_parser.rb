# frozen_string_literal: true

# Parses k8s yml files supporting:
#   - Multiple documents in a single yml file to use anchors and reuse values between components
#   - Config variables replacement
#   - Auto include secrets keys into deployments
# Sample: ruby kube/k8s_helper/yaml_parser.rb '../deployment.yml' 'kubectl create ' 'beta'

# ARGV[0] = Yml file path name
# ARGV[1] = K8s command
# ARGV[1] = Environment name, default beta

abort('Must define file name, sample: beta/deployment.yml') unless ARGV[0]
abort('Must define the command to run, sample: kubectl create') unless ARGV[1]

require 'yaml'
require 'json'
require_relative './helpers'

yml_path = ARGV[0]
k8s_command = ARGV[1]
@deploy_env = ARGV[2] || 'beta'

output_path = File.join(__dir__, 'tmp_result.yml')
file_path = yml_path.start_with?('/') ? yml_path : File.join(__dir__, yml_path)
parse_yml_file(file_path, output_path)

puts `#{k8s_command} -f #{output_path}`
