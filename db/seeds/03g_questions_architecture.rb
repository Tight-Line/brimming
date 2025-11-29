# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Architecture Space
# =============================================================================
puts "Creating Architecture questions..."

architecture_space = Space.find_by!(slug: "architecture")

# Saga pattern question
create_qa(
  space: architecture_space,
  author: SEED_EXPERTS["architect.lisa@example.com"],
  title: "Saga pattern vs 2PC for distributed transactions in microservices?",
  body: <<~BODY,
    We're breaking our monolith into microservices. Currently, our order processing involves:
    1. Create order
    2. Reserve inventory
    3. Process payment
    4. Send confirmation email

    All of these need to succeed or fail together. I've read about the Saga pattern and Two-Phase Commit (2PC). Which is better for microservices?

    Our tech stack: Ruby services, PostgreSQL, RabbitMQ for messaging.
  BODY
  answers: [
    {
      author: SEED_EXPERTS["dr.james.wilson@example.com"],
      body: <<~ANSWER,
        **Short answer: Use the Saga pattern for microservices.**

        Here's why:

        **Two-Phase Commit (2PC) problems:**
        - Requires all services to be available simultaneously
        - Coordinator is a single point of failure
        - Locks resources across services (hurts performance)
        - Doesn't work well with non-transactional systems (email, 3rd party APIs)
        - Violates microservices independence

        **Saga pattern advantages:**
        - Services remain loosely coupled
        - Each step is a local transaction
        - Compensating transactions handle failures
        - Works with any downstream system

        **For your order flow (Choreography-based Saga):**

        ```
        Order Service → publishes OrderCreated
        Inventory Service → listens, reserves, publishes InventoryReserved
        Payment Service → listens, charges, publishes PaymentProcessed
        Notification Service → listens, sends email

        If payment fails:
        Payment Service → publishes PaymentFailed
        Inventory Service → listens, releases reservation (compensating action)
        Order Service → listens, marks order as failed
        ```

        **Implementation in Ruby:**
        ```ruby
        # OrderSaga coordinates the flow
        class OrderSaga
          STEPS = [
            { action: :create_order, compensate: :cancel_order },
            { action: :reserve_inventory, compensate: :release_inventory },
            { action: :process_payment, compensate: :refund_payment },
            { action: :send_confirmation, compensate: :noop }
          ]

          def execute
            completed_steps = []
            STEPS.each do |step|
              result = send(step[:action])
              if result.success?
                completed_steps << step
              else
                rollback(completed_steps)
                return failure(result.error)
              end
            end
            success
          end

          def rollback(steps)
            steps.reverse.each { |step| send(step[:compensate]) }
          end
        end
        ```

        Consider using a dedicated Saga orchestrator gem like `rails_event_store` for production.
      ANSWER
      votes: 41,
      correct: true
    }
  ],
  created_ago: 25.days
)

# Event sourcing question (SCENARIO 5: No accepted answer)
create_qa(
  space: architecture_space,
  author: SEED_EXPERTS["senior.rachel@example.com"],
  title: "Event sourcing vs traditional CRUD: when is the complexity worth it?",
  body: <<~BODY,
    We're designing a new order management system. The team is split between:

    1. Traditional CRUD with audit logging
    2. Full event sourcing with CQRS

    What factors should drive this decision? We have:
    - ~100k orders/day
    - Complex order states (draft, submitted, processing, fulfilled, etc.)
    - Need for full audit trail
    - Multiple downstream systems need order updates

    Looking for real-world experience, not just theory.
  BODY
  answers: [
    {
      author: SEED_EXPERTS["dr.james.wilson@example.com"],
      body: <<~ANSWER,
        I've implemented both approaches at scale. Here's my decision framework:

        **Choose Event Sourcing when:**
        - Audit trail is a legal/compliance requirement
        - You need to replay events to rebuild state
        - Business rules depend on the history (not just current state)
        - Multiple bounded contexts need different views of the data

        **Choose CRUD + audit log when:**
        - Simple state machines with clear transitions
        - Team is new to ES/CQRS patterns
        - Read-heavy workload with simple queries
        - You just need "who changed what when"

        **For your case (100k orders/day):**
        Consider a hybrid: use event sourcing for the order lifecycle but CRUD for reference data (products, customers). This gives you audit + replay for orders without overcomplicating everything.

        ```ruby
        class Order
          # Event sourced
          def submit!
            apply(OrderSubmitted.new(order_id: id, submitted_at: Time.current))
          end

          def apply(event)
            EventStore.append(event)
            process_event(event)  # Update read model
          end
        end
        ```
      ANSWER
      votes: 29,
      correct: false
    },
    {
      author: SEED_EXPERTS["architect.sam@example.com"],
      body: <<~ANSWER,
        Hot take: you almost certainly don't need event sourcing.

        At my previous company, we handled 500k orders/day with PostgreSQL + Postgres triggers for audit:

        ```sql
        CREATE TABLE order_audit (
          id BIGSERIAL PRIMARY KEY,
          order_id BIGINT,
          changed_at TIMESTAMP DEFAULT NOW(),
          changed_by INTEGER,
          old_values JSONB,
          new_values JSONB,
          operation VARCHAR(10)
        );
        ```

        Event sourcing adds:
        - Eventually consistent reads (confuses users)
        - Complex event versioning (events evolve!)
        - Debugging nightmare ("why is this order in this state?")
        - Team learning curve (6+ months to proficiency)

        The downstream system updates? Debezium + Kafka gives you change data capture without restructuring your entire domain.

        Don't let architecture astronauts convince you that you need ES. CRUD + good audit logging handles 99% of cases.
      ANSWER
      votes: 35,
      correct: false
    },
    {
      author: SEED_INTERMEDIATES["frontend.nadia@example.com"],
      body: <<~ANSWER,
        We went with event sourcing for a similar system and regretted it. The complexity was massive:

        - Event versioning when requirements changed
        - Snapshot management for performance
        - Debugging event sequences
        - Onboarding new developers

        If I could redo it, I'd use Rails state machines + paper_trail gem for audit. Would've saved us 6 months.

        ```ruby
        class Order < ApplicationRecord
          has_paper_trail

          state_machine :state, initial: :draft do
            event :submit do
              transition draft: :submitted
            end
          end
        end
        ```
      ANSWER
      votes: 22,
      correct: false
    }
  ],
  created_ago: 4.days
)

# Monorepo question
create_qa(
  space: architecture_space,
  author: SEED_EXPERTS["tech.lead.omar@example.com"],
  title: "Monorepo vs polyrepo for microservices: what's your experience?",
  body: <<~BODY,
    We're restructuring our codebase (15 microservices, 8 developers). Currently polyrepo but considering monorepo.

    **Current pain points with polyrepo:**
    - Dependency version drift between services
    - Cross-service changes require multiple PRs
    - Inconsistent tooling/linting across repos

    **Concerns about monorepo:**
    - CI/CD complexity
    - Repository size growth
    - Access control (not everyone needs access to everything)

    What's your real-world experience? We're considering Nx or Turborepo.
  BODY
  answers: [
    {
      author: SEED_EXPERTS["architect.sam@example.com"],
      body: <<~ANSWER,
        Switched to monorepo (Nx) 2 years ago. **Best decision we made.**

        **What we gained:**
        - Atomic cross-service changes (one PR, one review)
        - Shared libraries actually stay shared
        - Consistent tooling enforced at root
        - Much easier onboarding

        **Nx specifically:**
        ```bash
        # Only build/test affected services
        nx affected --target=test --base=main

        # Dependency graph
        nx graph
        ```

        **CI/CD solution:**
        ```yaml
        # Only run CI for changed services
        - run: npx nx affected --target=build --base=origin/main
        ```

        **The "repo size" fear is overblown.** Git handles large repos fine. Google, Facebook, Microsoft all use monorepos.

        **Access control:** Use CODEOWNERS + branch protection. GitHub/GitLab support path-based rules.
      ANSWER
      votes: 36,
      correct: false
    },
    {
      author: SEED_EXPERTS["distinguished.eng@example.com"],
      body: <<~ANSWER,
        Counterpoint: we tried monorepo and went back to polyrepo. Here's why:

        **Monorepo problems we hit:**
        - **CI became the bottleneck.** Even with affected detection, someone else's broken test blocks your deploy.
        - **Git performance degraded.** `git status` took 5+ seconds.
        - **Merge conflicts exploded.** 8 devs = constant rebasing.
        - **The "atomic change" benefit is oversold.** Breaking changes still need coordination.

        **What actually solved our problems:**
        1. **Renovate bot** for automated dependency updates
        2. **Shared lint config** as npm package
        3. **API versioning** instead of coordinated deploys
        4. **Contract testing** (Pact) for service boundaries

        ```json
        {
          "extends": ["config:base"],
          "packageRules": [{
            "matchPackageNames": ["@company/*"],
            "automerge": true
          }]
        }
        ```

        Monorepo works for Google because they built Blaze/Bazel. For most teams, polyrepo + good automation is simpler.
      ANSWER
      votes: 28,
      correct: false
    }
  ],
  created_ago: 2.days
)

puts "  Created Architecture questions"
