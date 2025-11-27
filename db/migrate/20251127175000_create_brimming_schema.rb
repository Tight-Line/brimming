# frozen_string_literal: true

class CreateBrimmingSchema < ActiveRecord::Migration[8.1]
  def up
    execute "CREATE SCHEMA IF NOT EXISTS brimming"
  end

  def down
    execute "DROP SCHEMA IF EXISTS brimming CASCADE"
  end
end
