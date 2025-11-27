# frozen_string_literal: true

# SimpleCov must be started before any application code is loaded
require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  minimum_coverage line: 100, branch: 100
  add_filter "/spec/"
  add_filter "/config/"
  add_filter "/db/"
  add_filter "/vendor/"

  # Exclude Rails base classes until they contain custom logic
  add_filter "app/controllers/application_controller.rb"
  add_filter "app/jobs/application_job.rb"
  add_filter "app/mailers/application_mailer.rb"

  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Services", "app/services"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"
  add_group "Policies", "app/policies"
  add_group "Helpers", "app/helpers"
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Focus on tagged examples
  config.filter_run_when_matching :focus

  # Persist example status for --only-failures
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Disable monkey patching
  config.disable_monkey_patching!

  # Use documentation formatter for single file runs
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  # Profile slow examples
  config.profile_examples = 10

  # Random order
  config.order = :random
  Kernel.srand config.seed
end
