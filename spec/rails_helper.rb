# frozen_string_literal: true

require "spec_helper"

# CRITICAL: Abort if trying to run specs without RAILS_ENV=test
# The dev container sets RAILS_ENV=development by default, so we must
# explicitly set RAILS_ENV=test when running specs, otherwise the
# development database will be wiped by database_cleaner.
#
# Use: RAILS_ENV=test bundle exec rspec
# Or:  make test
if ENV["RAILS_ENV"] && ENV["RAILS_ENV"] != "test"
  abort <<~ERROR
    ========================================================================
    ERROR: Refusing to run specs with RAILS_ENV=#{ENV["RAILS_ENV"]}

    Running specs without RAILS_ENV=test will DESTROY your #{ENV["RAILS_ENV"]} database!

    Use one of these instead:
      make test
      make test SPEC=spec/path/to/spec.rb
      RAILS_ENV=test bundle exec rspec

    ========================================================================
  ERROR
end

ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "database_cleaner/active_record"
require "shoulda/matchers"
require "webmock/rspec"

# Allow localhost connections for test database
WebMock.disable_net_connect!(allow_localhost: true)

# Require all support files
Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# Force routes to load before tests run.
# This ensures Devise mappings are populated before any test calls sign_in.
# Without this, tests may fail randomly depending on execution order.
Rails.application.routes.recognize_path("/") rescue nil

RSpec.configure do |config|
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]
  config.use_transactional_fixtures = false

  # Infer spec type from file location
  config.infer_spec_type_from_file_location!

  # Filter Rails gems from backtraces
  config.filter_rails_from_backtrace!

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Include Devise test helpers for request specs
  config.include Devise::Test::IntegrationHelpers, type: :request

  # Include ActiveJob test helpers and use :test queue adapter
  config.include ActiveJob::TestHelper
  config.before(:each) do
    ActiveJob::Base.queue_adapter = :test
  end

  # DatabaseCleaner configuration
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

# Shoulda Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
