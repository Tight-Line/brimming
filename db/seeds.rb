# frozen_string_literal: true

# Brimming Seed Data
# Creates realistic sample data for development and demonstration purposes
#
# Run with: rails db:seed
# Reset with: rails db:seed:replant
#
# Seed files are split into multiple files in db/seeds/ directory
# and are loaded in alphabetical order.

# Load all seed files from db/seeds/ in sorted order
Dir[Rails.root.join("db/seeds/*.rb")].sort.each do |file|
  load file
end
