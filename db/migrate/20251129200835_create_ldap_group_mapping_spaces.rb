# frozen_string_literal: true

class CreateLdapGroupMappingSpaces < ActiveRecord::Migration[8.1]
  def change
    create_table :ldap_group_mapping_spaces do |t|
      t.references :ldap_group_mapping, null: false, foreign_key: true
      t.references :space, null: false, foreign_key: true

      t.timestamps
    end

    add_index :ldap_group_mapping_spaces, [ :ldap_group_mapping_id, :space_id ],
              unique: true, name: "idx_ldap_group_mapping_spaces_unique"
  end
end
