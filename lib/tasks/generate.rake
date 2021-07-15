# frozen_string_literal: true

namespace :kubernetes_helper do
  desc 'Generate template files'
  task :generate do
    ARGV.each { |a| task a.to_sym do; end }
    # TODO: ...
  end
end
