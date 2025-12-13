source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Authentication [https://github.com/heartcombo/devise]
gem "devise", "~> 4.9"

# Authorization [https://github.com/varvet/pundit]
gem "pundit", "~> 2.4"

# OmniAuth for SSO [https://github.com/omniauth/omniauth]
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 2.0"

# LDAP authentication [https://github.com/intridea/omniauth-ldap]
gem "omniauth-ldap", "~> 2.0"

# Net-LDAP for direct LDAP queries (group membership)
gem "net-ldap", "~> 0.19"

# Markdown rendering with syntax highlighting
gem "redcarpet", "~> 3.6"
gem "rouge", "~> 4.0"

# Document text extraction for article indexing
gem "pdf-reader", "~> 2.12"  # PDF text extraction
gem "docx", "~> 0.8"         # Word document extraction
gem "roo", "~> 3.0"          # Excel spreadsheet extraction
gem "csv"                    # Required by roo (not default in Ruby 3.4+)

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Solid Stack - database-backed queue, cache, and cable
gem "solid_queue"
gem "solid_cache"
gem "solid_cable"
gem "mission_control-jobs"

# Firecrawl.dev cloud API for web scraping
gem "firecrawl"

# pgvector support for vector similarity search
gem "neighbor", "~> 0.5"

# Unified LLM client for multiple providers [https://github.com/crmne/ruby_llm]
gem "ruby_llm", "~> 1.0"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Active Storage validations [https://github.com/igorkasyanchuk/active_storage_validations]
gem "active_storage_validations", "~> 2.0"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Testing framework
  gem "rspec-rails", "~> 8.0"

  # Test factories
  gem "factory_bot_rails", "~> 6.0"

  # Generate fake data for tests and seeds
  gem "faker", "~> 3.5"
end

group :test do
  # Code coverage
  gem "simplecov", require: false

  # One-liner tests for common Rails functionality
  gem "shoulda-matchers", "~> 7.0"

  # Clean database between tests
  gem "database_cleaner-active_record", "~> 2.0"

  # HTTP request stubbing for external API tests
  gem "webmock", "~> 3.0"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Preview emails in the browser instead of sending [https://github.com/ryanb/letter_opener]
  gem "letter_opener"
end

gem "importmap-rails", "~> 2.2"
