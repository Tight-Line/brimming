# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Security Space
# =============================================================================
puts "Creating Security questions..."

security_space = Space.find_by!(slug: "security")

# Password reset tokens question
create_qa(
  space: security_space,
  author: SEED_INTERMEDIATES["frontend.emma@example.com"],
  title: "How to properly implement password reset tokens in Rails?",
  body: <<~BODY,
    I'm implementing password reset functionality. Currently I'm generating tokens like this:

    ```ruby
    user.update(reset_token: SecureRandom.hex(32))
    ```

    Is this secure? What's the best practice for password reset tokens?
  BODY
  answers: [
    {
      author: SEED_EXPERTS["senior.dev.mike@example.com"],
      body: <<~ANSWER,
        Your approach has a critical security flaw: **storing plain tokens in the database**.

        If your database is compromised, attackers can reset any user's password.

        **Best practice: Store hashed tokens**

        ```ruby
        class User < ApplicationRecord
          def generate_password_reset!
            raw_token = SecureRandom.urlsafe_base64(32)
            update!(
              password_reset_token: Digest::SHA256.hexdigest(raw_token),
              password_reset_sent_at: Time.current
            )
            raw_token  # Send this in email
          end

          def self.find_by_reset_token(token)
            hashed = Digest::SHA256.hexdigest(token)
            find_by(password_reset_token: hashed)
          end

          def password_reset_valid?
            password_reset_sent_at > 2.hours.ago
          end
        end
        ```

        **Key security measures:**
        1. ✅ Hash the token before storing
        2. ✅ Use `urlsafe_base64` for email-safe tokens
        3. ✅ Expire tokens (2 hours is common)
        4. ✅ Invalidate token after use
        5. ✅ Use constant-time comparison for token lookup

        **Or just use Devise** - it handles all of this correctly out of the box.
      ANSWER
      votes: 35,
      correct: true,
      edited: true
    }
  ],
  created_ago: 6.days
)

# API keys storage question (SCENARIO 4: Middle-ground answer)
create_qa(
  space: security_space,
  author: SEED_INTERMEDIATES["dev.marcus@example.com"],
  title: "How to store API keys securely in a Rails application?",
  body: <<~BODY,
    I need to store third-party API keys (Stripe, SendGrid, etc.) for my Rails app.

    Currently using environment variables but wondering if there's a better way.

    What are the security best practices here?
  BODY
  answers: [
    {
      author: SEED_INTERMEDIATES["coder.brian@example.com"],
      body: <<~ANSWER,
        Environment variables are the standard approach. Use dotenv for development:

        ```ruby
        # .env (gitignored)
        STRIPE_SECRET_KEY=sk_live_xxx

        # Usage
        Stripe.api_key = ENV['STRIPE_SECRET_KEY']
        ```

        In production, set them in your hosting platform (Heroku, AWS, etc.).
      ANSWER
      votes: 24,
      correct: false
    },
    {
      author: SEED_EXPERTS["distinguished.eng@example.com"],
      body: <<~ANSWER,
        Rails 7.1+ has built-in encrypted credentials - use them:

        ```bash
        rails credentials:edit --environment production
        ```

        ```yaml
        # config/credentials/production.yml.enc
        stripe:
          secret_key: sk_live_xxx
          webhook_secret: whsec_xxx
        ```

        Access with:
        ```ruby
        Rails.application.credentials.stripe[:secret_key]
        ```

        **Advantages over ENV vars:**
        - Encrypted at rest (can commit to repo safely)
        - Typed structure (YAML vs flat strings)
        - Per-environment files
        - Version controlled (easier to audit changes)

        Store the master key (`config/credentials/production.key`) in your CI/CD secrets or hosting platform's secret manager.
      ANSWER
      votes: 31,
      correct: false
    },
    {
      author: SEED_EXPERTS["staff.eng.nina@example.com"],
      body: <<~ANSWER,
        The best approach depends on your scale:

        **Small projects**: Rails credentials (as described above) are excellent.

        **Medium/Enterprise**: Use a secrets manager:
        ```ruby
        # AWS Secrets Manager
        client = Aws::SecretsManager::Client.new
        secret = JSON.parse(client.get_secret_value(secret_id: 'prod/stripe').secret_string)
        Stripe.api_key = secret['api_key']
        ```

        **Key security principles regardless of approach:**

        1. **Rotate keys regularly** - automate this
        2. **Least privilege** - use restricted API keys when possible
        3. **Audit access** - log when secrets are accessed
        4. **Separate by environment** - never share keys between prod/staging

        **For Stripe specifically:**
        ```ruby
        # Use restricted keys!
        Stripe.api_key = Rails.application.credentials.dig(:stripe, :restricted_key)

        # Better: scope to specific actions
        Stripe::Customer.create({email: email}, {api_key: restricted_key})
        ```

        The env var vs credentials debate matters less than having a rotation strategy and proper access controls.
      ANSWER
      votes: 18,
      correct: true
    }
  ],
  created_ago: 9.days
)

puts "  Created Security questions"
