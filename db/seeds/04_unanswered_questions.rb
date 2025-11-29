# frozen_string_literal: true

# =============================================================================
# Questions Without Answers (unanswered)
# =============================================================================
puts "Creating unanswered questions..."

# Use shared user lookups from 03_questions_header.rb

# Look up spaces
rails_space = Space.find_by!(slug: "ruby-on-rails")
js_space = Space.find_by!(slug: "javascript")
devops_space = Space.find_by!(slug: "devops")
testing_space = Space.find_by!(slug: "testing")
databases_space = Space.find_by!(slug: "databases")
security_space = Space.find_by!(slug: "security")
architecture_space = Space.find_by!(slug: "architecture")

unanswered_questions = []

# Recent unanswered question - expert level
unanswered_questions << Question.find_or_create_by!(
  title: "How to implement rate limiting with Redis in a distributed Rails environment?"
) do |q|
  q.space = rails_space
  q.user = SEED_INTERMEDIATES["backend.david@example.com"]
  q.body = <<~BODY
    I'm trying to implement API rate limiting across multiple Rails servers using Redis. The challenge is ensuring accurate counting when requests hit different servers.

    Current approach:
    ```ruby
    def rate_limited?
      key = "rate_limit:\#{current_user.id}:\#{Time.current.beginning_of_minute}"
      count = REDIS.incr(key)
      REDIS.expire(key, 60) if count == 1
      count > 100
    end
    ```

    Problems:
    1. Race condition between INCR and EXPIRE
    2. What happens if Redis goes down?
    3. Should I use sliding window instead of fixed window?

    Looking for production-tested patterns. We expect ~10k requests/second at peak.
  BODY
  q.created_at = 4.hours.ago
  q.updated_at = 4.hours.ago
end

# Unanswered newbie question
unanswered_questions << Question.find_or_create_by!(
  title: "how do i center a div?? nothing works"
) do |q|
  q.space = js_space
  q.user = SEED_NEWBIES["student.ivy@example.com"]
  q.body = <<~BODY
    ive been trying for like 2 hours to center this stupid div and nothing works

    ```css
    .container {
      margin: auto;
      text-align: center;
    }
    ```

    the div is still on the left side of the page??? i tried everything on stackoverflow already

    please help this is for my class project due tomorrow
  BODY
  q.created_at = 6.hours.ago
  q.updated_at = 6.hours.ago
end

# Unanswered intermediate question
unanswered_questions << Question.find_or_create_by!(
  title: "Best approach for handling large CSV imports in Rails without blocking?"
) do |q|
  q.space = rails_space
  q.user = SEED_INTERMEDIATES["junior.frank@example.com"]
  q.body = <<~BODY
    Our users need to import CSV files with 100k+ rows. Currently, the import runs synchronously and times out.

    I'm considering:
    1. Background job with Sidekiq
    2. Streaming the CSV and processing in batches
    3. Using PostgreSQL COPY command directly

    What's the recommended pattern? Need to show progress to users and handle validation errors gracefully.
  BODY
  q.created_at = 1.day.ago
  q.updated_at = 1.day.ago
end

# More unanswered questions in different categories
unanswered_questions << Question.find_or_create_by!(
  title: "Debugging intermittent test failures in RSpec with database cleaner"
) do |q|
  q.space = testing_space
  q.user = SEED_INTERMEDIATES["dev.ashley@example.com"]
  q.body = <<~BODY
    We have flaky tests that pass locally but fail randomly in CI. Using DatabaseCleaner with transaction strategy.

    The failures seem related to data bleeding between tests, but I can't reproduce it locally.

    ```ruby
    RSpec.configure do |config|
      config.use_transactional_fixtures = false

      config.before(:suite) do
        DatabaseCleaner.strategy = :transaction
        DatabaseCleaner.clean_with(:truncation)
      end
    end
    ```

    Any debugging strategies for tracking down the root cause?
  BODY
  q.created_at = 2.days.ago
  q.updated_at = 2.days.ago
end

unanswered_questions << Question.find_or_create_by!(
  title: "PostgreSQL query plan changes after VACUUM - how to stabilize?"
) do |q|
  q.space = databases_space
  q.user = SEED_EXPERTS["principal.eng.tom@example.com"]
  q.body = <<~BODY
    We noticed that a critical query's execution plan changes dramatically after running VACUUM ANALYZE, sometimes choosing a much slower plan.

    ```sql
    EXPLAIN ANALYZE SELECT * FROM orders
    JOIN order_items ON orders.id = order_items.order_id
    WHERE orders.created_at > NOW() - INTERVAL '30 days'
    AND orders.status = 'completed';
    ```

    Before VACUUM: 50ms (uses index)
    After VACUUM: 2500ms (sequential scan)

    Table stats look reasonable. Is there a way to hint the planner or lock in a good plan?
  BODY
  q.created_at = 5.days.ago
  q.updated_at = 5.days.ago
end

# More unanswered questions
unanswered_questions << Question.find_or_create_by!(
  title: "How to structure a multi-tenant Rails application?"
) do |q|
  q.space = rails_space
  q.user = SEED_INTERMEDIATES["dev.hannah@example.com"]
  q.body = <<~BODY
    Building a SaaS platform where each customer (tenant) should have isolated data. Considering:

    1. Shared database with tenant_id column
    2. Schema-per-tenant (PostgreSQL schemas)
    3. Database-per-tenant

    We expect 100-500 tenants initially. Most will be small (< 1000 records) but a few will be large (millions).

    What's the recommended approach? Any gems to help with this?
  BODY
  q.created_at = 8.hours.ago
  q.updated_at = 8.hours.ago
end

unanswered_questions << Question.find_or_create_by!(
  title: "WebSocket authentication best practices?"
) do |q|
  q.space = security_space
  q.user = SEED_INTERMEDIATES["web.julia@example.com"]
  q.body = <<~BODY
    Implementing real-time features with WebSockets. How should authentication work?

    Current REST API uses JWT in headers, but WebSocket doesn't support custom headers in browser.

    Options I'm considering:
    1. Token in query string (feels insecure)
    2. Cookie-based auth
    3. First message contains token

    What's the secure approach here?
  BODY
  q.created_at = 3.hours.ago
  q.updated_at = 3.hours.ago
end

unanswered_questions << Question.find_or_create_by!(
  title: "GraphQL vs REST for mobile app backend?"
) do |q|
  q.space = architecture_space
  q.user = SEED_INTERMEDIATES["fullstack.laura@example.com"]
  q.body = <<~BODY
    Building a backend that will serve both web and mobile (iOS/Android) clients.

    Mobile team prefers GraphQL for flexible queries. Backend team prefers REST for simplicity.

    Is GraphQL worth the complexity? We have ~40 endpoints currently.
  BODY
  q.created_at = 18.hours.ago
  q.updated_at = 18.hours.ago
end

unanswered_questions << Question.find_or_create_by!(
  title: "Async/await vs callbacks in Node.js - performance difference?"
) do |q|
  q.space = js_space
  q.user = SEED_NEWBIES["beginner.quinn@example.com"]
  q.body = <<~BODY
    my friend says async/await is slower than callbacks because of overhead

    is this true? should i avoid async/await for performance?

    ```javascript
    // callback style
    db.query('SELECT * FROM users', (err, result) => {
      // handle result
    });

    // async/await
    const result = await db.query('SELECT * FROM users');
    ```
  BODY
  q.created_at = 2.hours.ago
  q.updated_at = 2.hours.ago
end

unanswered_questions << Question.find_or_create_by!(
  title: "Docker layer caching not working in GitHub Actions"
) do |q|
  q.space = devops_space
  q.user = SEED_INTERMEDIATES["backend.kevin@example.com"]
  q.body = <<~BODY
    Our Docker builds in GitHub Actions take 15+ minutes because layers aren't being cached.

    ```yaml
    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: myapp:latest
        cache-from: type=gha
        cache-to: type=gha,mode=max
    ```

    The cache shows as "restored" but docker still rebuilds everything from scratch. What am I missing?
  BODY
  q.created_at = 10.hours.ago
  q.updated_at = 10.hours.ago
end

puts "  Created #{unanswered_questions.count} unanswered questions"
