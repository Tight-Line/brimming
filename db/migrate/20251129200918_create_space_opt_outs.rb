# frozen_string_literal: true

class CreateSpaceOptOuts < ActiveRecord::Migration[8.1]
  def change
    create_table :space_opt_outs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :space, null: false, foreign_key: true
      t.references :ldap_group_mapping, null: false, foreign_key: true

      t.timestamps
    end

    # User can only opt out of a space once per mapping
    add_index :space_opt_outs, [ :user_id, :space_id, :ldap_group_mapping_id ],
              unique: true, name: "idx_space_opt_outs_unique"
  end
end
