# frozen_string_literal: true

require 'spec_helper'
RSpec.describe KubernetesHelper do
  describe 'when loading settings' do
    it 'loads the settings' do
      expect(KubernetesHelper.load_settings).to be_a(Hash)
    end

    it 'includes job_apps with data from old settings' do
      settings = {
        deployment: {
          job_name: 'job-name',
          job_resources: { test: true }
        }
      }
      res = described_class.job_apps_from_old_settings(settings)
      expect(res.first).to match(hash_including(name: 'job-name'))
      expect(res.first).to match(hash_including(resources: { test: true }))
    end
  end
end
