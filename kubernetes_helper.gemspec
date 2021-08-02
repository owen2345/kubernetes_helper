# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__) # rubocop:disable Style/SpecialGlobalVars
require_relative 'lib/kubernetes_helper/version'

Gem::Specification.new do |spec|
  spec.name          = 'kubernetes_helper'
  spec.version       = KubernetesHelper::VERSION
  spec.authors       = ['owen2345']
  spec.email         = ['owenperedo@gmail.com']

  spec.summary       = 'Kubernetes helper to manage deployment files'
  spec.description   = spec.description
  spec.homepage      = 'https://github.com/owen2345/kubernetes_helper'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 1') # rubocop:disable Gemspec/RequiredRubyVersion

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/owen2345/kubernetes_helper'
  spec.metadata['changelog_uri'] = 'https://github.com/owen2345/kubernetes_helper'

  spec.files = Dir['{app,config,db,lib,exe}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.add_dependency 'erb'
end
