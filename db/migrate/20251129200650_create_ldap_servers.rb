# frozen_string_literal: true

class CreateLdapServers < ActiveRecord::Migration[8.1]
  def change
    create_table :ldap_servers do |t|
      t.string :name, null: false
      t.string :host, null: false
      t.integer :port, null: false, default: 389
      t.string :encryption, null: false, default: "plain"
      t.string :bind_dn
      t.string :bind_password
      t.string :user_search_base, null: false
      t.string :user_search_filter, default: "(uid=%{username})"
      t.string :group_search_base
      t.string :group_search_filter, default: "(member=%{dn})"
      t.string :uid_attribute, null: false, default: "uid"
      t.string :email_attribute, null: false, default: "mail"
      t.string :name_attribute, default: "cn"
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    add_index :ldap_servers, :name, unique: true
    add_index :ldap_servers, :enabled
  end
end
