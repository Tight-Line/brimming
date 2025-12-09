class MigrateExistingEmailsToUserEmails < ActiveRecord::Migration[8.1]
  def up
    # Copy existing user emails to user_emails table
    # Mark them as primary and verified (existing users can already log in)
    execute <<~SQL
      INSERT INTO user_emails (user_id, email, "primary", verified, verified_at, created_at, updated_at)
      SELECT id, email, true, true, created_at, created_at, updated_at
      FROM users
      WHERE email IS NOT NULL AND email != ''
      ON CONFLICT (email) DO NOTHING
    SQL
  end

  def down
    # Remove all user_emails that match users.email (the migrated ones)
    execute <<~SQL
      DELETE FROM user_emails
      WHERE "primary" = true
    SQL
  end
end
