class CreateUserEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :user_emails do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email, null: false
      t.boolean :primary, null: false, default: false
      t.boolean :verified, null: false, default: false
      t.datetime :verified_at
      t.string :verification_token

      t.timestamps
    end

    add_index :user_emails, :email, unique: true
    add_index :user_emails, :verification_token, unique: true, where: "verification_token IS NOT NULL"
    # Ensure only one primary email per user
    add_index :user_emails, [ :user_id, :primary ], unique: true, where: '"primary" = true'
  end
end
