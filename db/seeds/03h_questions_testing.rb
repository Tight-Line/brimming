# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Testing Space
# =============================================================================
puts "Creating Testing questions..."

testing_space = Space.find_by!(slug: "testing")

# VCR vs WebMock question
create_qa(
  space: testing_space,
  author: SEED_INTERMEDIATES["coder.brian@example.com"],
  title: "Should I mock external API calls in unit tests or use VCR cassettes?",
  body: <<~BODY,
    I'm testing a service that calls the Stripe API. I've seen two approaches:

    1. **Mocking with WebMock:**
    ```ruby
    stub_request(:post, "https://api.stripe.com/v1/charges")
      .to_return(status: 200, body: { id: "ch_123" }.to_json)
    ```

    2. **Recording with VCR:**
    ```ruby
    VCR.use_cassette("stripe_charge") do
      result = PaymentService.charge(amount: 1000)
    end
    ```

    Which approach is better? When should I use each?
  BODY
  answers: [
    {
      author: SEED_EXPERTS["senior.dev.mike@example.com"],
      body: <<~ANSWER,
        Both are valid - use them for different purposes:

        **Use WebMock/mocks when:**
        - Testing specific edge cases (network errors, timeouts, malformed responses)
        - Testing error handling paths
        - You need fine-grained control over response timing
        - Tests need to be deterministic and fast

        **Use VCR when:**
        - You want to test against real API responses
        - Initial development (record once, replay forever)
        - API has complex response structures you don't want to construct manually
        - Integration tests where accuracy matters more than speed

        **My recommended approach: Both!**

        ```ruby
        # spec/services/payment_service_spec.rb
        RSpec.describe PaymentService do
          describe "#charge", :vcr do  # Use VCR for happy path
            it "creates a charge" do
              result = described_class.charge(amount: 1000)
              expect(result.id).to match(/^ch_/)
            end
          end

          describe "#charge error handling" do  # Use mocks for edge cases
            it "handles network timeouts" do
              stub_request(:post, /stripe/).to_timeout
              expect { described_class.charge(amount: 1000) }
                .to raise_error(PaymentService::TimeoutError)
            end

            it "handles invalid card errors" do
              stub_request(:post, /stripe/).to_return(
                status: 402,
                body: { error: { type: "card_error" } }.to_json
              )
              expect { described_class.charge(amount: 1000) }
                .to raise_error(PaymentService::CardError)
            end
          end
        end
        ```

        **Pro tip:** For Stripe specifically, consider using `stripe-ruby-mock` gem which provides realistic mock responses.
      ANSWER
      votes: 18,
      correct: true
    }
  ],
  created_ago: 14.days
)

# Test coverage debate
create_qa(
  space: testing_space,
  author: SEED_INTERMEDIATES["backend.kevin@example.com"],
  title: "How much test coverage is enough? Our team debates 80% vs 100%",
  body: <<~BODY,
    Our team has an ongoing debate about test coverage targets:

    - Some say 100% coverage is the only way to ensure quality
    - Others say 80% is enough and diminishing returns after that
    - A few think coverage metrics are useless

    What's the right approach? We're a Rails app with ~200 models.
  BODY
  answers: [
    {
      author: SEED_EXPERTS["senior.dev.mike@example.com"],
      body: <<~ANSWER,
        **100% coverage** is achievable and worthwhile for critical systems:

        ```ruby
        # SimpleCov in spec_helper.rb
        SimpleCov.start 'rails' do
          minimum_coverage 100
          refuse_coverage_drop
        end
        ```

        Benefits:
        - Forces you to write testable code
        - Catches edge cases you'd otherwise miss
        - Safe refactoring with confidence
        - No "I'll test this later" tech debt

        We maintain 100% on a payment system. The few extra tests for edge cases have caught production bugs multiple times.
      ANSWER
      votes: 16,
      correct: false
    },
    {
      author: SEED_EXPERTS["principal.eng.tom@example.com"],
      body: <<~ANSWER,
        **Coverage percentage is a terrible metric.** Here's why:

        ```ruby
        # 100% coverage, 0% confidence
        it "calls the method" do
          user.full_name  # Covered! But what does it return?
        end

        # Proper test
        it "combines first and last name" do
          user = User.new(first_name: "Jane", last_name: "Doe")
          expect(user.full_name).to eq("Jane Doe")
        end
        ```

        **Focus on:**
        1. Critical path coverage (happy paths + error handling)
        2. Mutation testing (does changing code break tests?)
        3. Integration tests for workflows

        ```bash
        # Mutation testing reveals weak tests
        bundle exec mutant --use rspec User
        ```

        I've seen 95% coverage codebases with terrible tests. Coverage measures execution, not verification.
      ANSWER
      votes: 45,
      correct: false
    },
    {
      author: SEED_MODERATORS["sarah.chen@example.com"],
      body: <<~ANSWER,
        After years of this debate, here's what actually works:

        **Pragmatic approach:**
        - **Models/Services**: 100% (core business logic)
        - **Controllers**: 90%+ (request specs for main flows)
        - **Views**: Skip (too brittle, use system tests for critical UI)
        - **Admin panels**: 70% (lower risk, higher churn)

        ```ruby
        # Exclude low-value files
        SimpleCov.start 'rails' do
          add_filter '/admin/'
          add_filter '/concerns/'  # if trivial
        end
        ```

        **The real metrics that matter:**
        1. Test execution time (fast = run more often)
        2. Flakiness rate (< 0.1% or fix immediately)
        3. Bug escape rate (how many prod bugs had no tests?)

        Chasing 100% everywhere leads to brittle tests and slow CI. Focus your testing energy where bugs are costly.
      ANSWER
      votes: 33,
      correct: true
    }
  ],
  created_ago: 8.days
)

puts "  Created Testing questions"
