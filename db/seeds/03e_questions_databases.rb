# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Databases Space
# =============================================================================
puts "Creating Databases questions..."

databases_space = Space.find_by!(slug: "databases")

# Composite index question
create_qa(
  space: databases_space,
  author: SEED_INTERMEDIATES["junior.frank@example.com"],
  title: "When should I use a composite index vs separate indexes in PostgreSQL?",
  body: <<~BODY,
    I have a table with queries that filter on multiple columns:

    ```sql
    SELECT * FROM orders
    WHERE user_id = 123 AND status = 'pending' AND created_at > '2024-01-01';
    ```

    Should I create:
    - One composite index: `(user_id, status, created_at)`
    - Three separate indexes: `(user_id)`, `(status)`, `(created_at)`

    What are the trade-offs?
  BODY
  answers: [
    {
      author: SEED_EXPERTS["dr.james.wilson@example.com"],
      body: <<~ANSWER,
        Great question! Here's the decision framework:

        **Use a composite index when:**
        - Queries frequently filter on the same combination of columns
        - Column order matches your query patterns (leftmost columns first)
        - You need to avoid bitmap heap scans on large tables

        **Use separate indexes when:**
        - Queries use different combinations of columns
        - You have many different query patterns
        - Storage space is a concern

        **For your specific query:**
        ```sql
        -- Best: Composite index matching query pattern
        CREATE INDEX idx_orders_user_status_created
        ON orders (user_id, status, created_at);
        ```

        **Why this order?**
        1. `user_id` - Most selective (unique per user)
        2. `status` - Equality condition
        3. `created_at` - Range condition (must be last)

        **Verification:**
        ```sql
        EXPLAIN ANALYZE SELECT * FROM orders
        WHERE user_id = 123 AND status = 'pending' AND created_at > '2024-01-01';
        ```

        You should see "Index Scan" not "Bitmap Heap Scan" or "Seq Scan".

        **Trade-off**: Composite indexes are larger and slower to update, but much faster for reads when the query matches the index pattern.
      ANSWER
      votes: 22,
      correct: true
    }
  ],
  created_ago: 12.days
)

# UUID vs auto-increment question (SCENARIO 3: Low vote correct answer)
create_qa(
  space: databases_space,
  author: SEED_INTERMEDIATES["fullstack.laura@example.com"],
  title: "Should I use UUID or auto-increment for primary keys?",
  body: <<~BODY,
    New project, trying to decide between UUID and auto-increment integers for primary keys.

    We'll eventually have a distributed system with multiple databases. Does that affect the choice?

    PostgreSQL 15.
  BODY
  answers: [
    {
      author: SEED_INTERMEDIATES["backend.david@example.com"],
      body: <<~ANSWER,
        **Always use UUIDs!** Here's why:

        - No collisions in distributed systems
        - Can generate IDs client-side
        - No information leakage (can't guess other IDs)
        - Works great with microservices

        ```sql
        CREATE TABLE users (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          ...
        );
        ```

        The performance difference is negligible on modern hardware. We use UUIDs everywhere and never looked back.
      ANSWER
      votes: 34,
      correct: false
    },
    {
      author: SEED_EXPERTS["architect.sam@example.com"],
      body: <<~ANSWER,
        The answer is: **it depends**, and the UUID enthusiasm is often misguided.

        **UUIDs have real costs:**
        1. **Index fragmentation**: Random UUIDs cause B-tree page splits. On large tables, this means 3-4x more disk I/O.
        2. **Size**: 16 bytes vs 8 bytes matters when you have millions of foreign keys.
        3. **Cache efficiency**: Random access patterns hurt CPU cache.

        **Benchmark on 10M row table:**
        ```
        Insert rate with BIGSERIAL: 45,000/sec
        Insert rate with random UUID: 12,000/sec
        ```

        **My recommendation:**
        - **Use BIGSERIAL** for internal primary keys (performance)
        - **Add a UUID column** for external-facing identifiers

        ```sql
        CREATE TABLE users (
          id BIGSERIAL PRIMARY KEY,
          external_id UUID UNIQUE DEFAULT gen_random_uuid(),
          ...
        );
        ```

        For distributed systems, consider:
        - **UUIDv7** (time-ordered, coming in PG17)
        - **ULID** (lexicographically sortable)
        - **Snowflake IDs** (Twitter's approach)

        These give you distributed generation WITHOUT sacrificing index performance.
      ANSWER
      votes: 8,
      correct: true
    },
    {
      author: SEED_NEWBIES["newdev.maya@example.com"],
      body: <<~ANSWER,
        i just use auto increment because its simpler and my teacher said uuids are slow

        ```sql
        id SERIAL PRIMARY KEY
        ```

        works fine for me
      ANSWER
      votes: 2,
      correct: false
    }
  ],
  created_ago: 11.days
)

puts "  Created Databases questions"
