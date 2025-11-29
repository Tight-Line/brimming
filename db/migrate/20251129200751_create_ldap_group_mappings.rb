# frozen_string_literal: true

class CreateLdapGroupMappings < ActiveRecord::Migration[8.1]
  def change
    create_table :ldap_group_mappings do |t|
      t.references :ldap_server, null: false, foreign_key: true
      t.string :group_pattern, null: false
      t.string :pattern_type, null: false, default: "exact"

      t.timestamps
    end

    add_index :ldap_group_mappings, [ :ldap_server_id, :group_pattern ], unique: true
  end
end
