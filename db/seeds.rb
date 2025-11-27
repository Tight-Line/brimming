# frozen_string_literal: true

# Brimming Seed Data
# Creates realistic sample data for development and demonstration purposes
#
# Run with: rails db:seed
# Reset with: rails db:seed:replant

puts "Seeding database..."

# =============================================================================
# Users
# =============================================================================
puts "Creating users..."

# Admin user
admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.username = "admin"
  u.role = :admin
  u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=admin"
end

# Moderators
moderators = [
  { email: "sarah.chen@example.com", username: "sarahc" },
  { email: "marcus.johnson@example.com", username: "mjohnson" },
  { email: "elena.rodriguez@example.com", username: "erodriguez" }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.role = :moderator
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Expert users (high activity, well-written questions/answers)
experts = [
  { email: "dr.james.wilson@example.com", username: "drjwilson" },
  { email: "prof.aisha.patel@example.com", username: "apatel_prof" },
  { email: "senior.dev.mike@example.com", username: "mike_seniordev" },
  { email: "architect.lisa@example.com", username: "lisa_architect" },
  { email: "principal.eng.tom@example.com", username: "tom_principal" }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Intermediate users
intermediates = [
  { email: "dev.ashley@example.com", username: "ashley_dev" },
  { email: "coder.brian@example.com", username: "brian_codes" },
  { email: "fullstack.carol@example.com", username: "carol_fs" },
  { email: "backend.david@example.com", username: "david_backend" },
  { email: "frontend.emma@example.com", username: "emma_frontend" },
  { email: "junior.frank@example.com", username: "frank_jr" },
  { email: "learner.grace@example.com", username: "grace_learning" }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Newbie users (often poorly-phrased questions)
newbies = [
  { email: "newbie.henry@example.com", username: "henry_newbie" },
  { email: "student.ivy@example.com", username: "ivy_student" },
  { email: "beginner.jack@example.com", username: "jack_beginner" },
  { email: "learning.kate@example.com", username: "kate_learn" },
  { email: "first.timer.leo@example.com", username: "leo_firsttime" }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

all_users = [ admin ] + moderators + experts + intermediates + newbies

puts "  Created #{all_users.count} users"

# =============================================================================
# Categories
# =============================================================================
puts "Creating categories..."

categories_data = [
  {
    name: "Ruby on Rails",
    slug: "ruby-on-rails",
    description: "Questions about Ruby on Rails web framework, including ActiveRecord, ActionController, and Rails best practices."
  },
  {
    name: "JavaScript",
    slug: "javascript",
    description: "Questions about JavaScript, ES6+, async programming, DOM manipulation, and browser APIs."
  },
  {
    name: "Python",
    slug: "python",
    description: "Questions about Python programming, including Django, Flask, data science libraries, and Pythonic practices."
  },
  {
    name: "DevOps",
    slug: "devops",
    description: "Questions about CI/CD, Docker, Kubernetes, infrastructure as code, and deployment strategies."
  },
  {
    name: "Databases",
    slug: "databases",
    description: "Questions about SQL, NoSQL, database design, query optimization, and data modeling."
  },
  {
    name: "Security",
    slug: "security",
    description: "Questions about application security, authentication, authorization, and secure coding practices."
  },
  {
    name: "Architecture",
    slug: "architecture",
    description: "Questions about software architecture, design patterns, microservices, and system design."
  },
  {
    name: "Testing",
    slug: "testing",
    description: "Questions about unit testing, integration testing, TDD, and testing frameworks."
  }
]

categories = categories_data.map do |attrs|
  Category.find_or_create_by!(slug: attrs[:slug]) do |c|
    c.name = attrs[:name]
    c.description = attrs[:description]
  end
end

puts "  Created #{categories.count} categories"

# Assign category moderators
puts "Assigning category moderators..."
rails_cat = categories.find { |c| c.slug == "ruby-on-rails" }
js_cat = categories.find { |c| c.slug == "javascript" }
python_cat = categories.find { |c| c.slug == "python" }
devops_cat = categories.find { |c| c.slug == "devops" }

rails_cat.add_moderator(moderators[0])
rails_cat.add_moderator(experts[2])
js_cat.add_moderator(moderators[1])
python_cat.add_moderator(moderators[2])
devops_cat.add_moderator(moderators[0])

puts "  Assigned moderators to categories"

# =============================================================================
# Questions and Answers
# =============================================================================
puts "Creating questions and answers..."

# Helper to create a question with answers
def create_qa(category:, author:, title:, body:, answers:, created_ago: rand(1..90).days)
  question = Question.find_or_create_by!(title: title) do |q|
    q.category = category
    q.user = author
    q.body = body
    q.created_at = created_ago.ago
    q.updated_at = created_ago.ago
  end

  answers.each_with_index do |answer_data, index|
    answer = Answer.find_or_create_by!(question: question, user: answer_data[:author]) do |a|
      a.body = answer_data[:body]
      a.vote_score = answer_data[:votes] || 0
      a.is_correct = answer_data[:correct] || false
      a.created_at = (created_ago - (index + 1).hours).ago
      a.updated_at = (created_ago - (index + 1).hours).ago
    end

    # Create actual votes to match vote_score
    if answer_data[:votes] && answer_data[:votes] > 0
      voters = User.where.not(id: [ answer_data[:author].id, author.id ]).sample(answer_data[:votes].abs)
      voters.each do |voter|
        Vote.find_or_create_by!(answer: answer, user: voter) do |v|
          v.value = answer_data[:votes].positive? ? 1 : -1
        end
      end
    end
  end

  question
end

# -----------------------------------------------------------------------------
# Ruby on Rails Questions
# -----------------------------------------------------------------------------

# Expert-level Rails question
create_qa(
  category: rails_cat,
  author: experts[0],
  title: "Optimizing N+1 queries in complex ActiveRecord associations with polymorphic relationships",
  body: <<~BODY,
    I'm working on a large-scale Rails application where we have a polymorphic `Commentable` association. Our `Comment` model belongs to `commentable`, which can be a `Post`, `Article`, or `Product`.

    The current implementation suffers from N+1 queries when loading comments with their associated commentable objects. Here's the relevant code:

    ```ruby
    class Comment < ApplicationRecord
      belongs_to :commentable, polymorphic: true
      belongs_to :user
    end

    class CommentsController < ApplicationController
      def index
        @comments = Comment.includes(:user).recent.page(params[:page])
        # This causes N+1 when accessing comment.commentable
      end
    end
    ```

    I've tried using `includes(:commentable)` but it doesn't work with polymorphic associations. I've also looked into `eager_load` and `preload` without success.

    Our metrics show this endpoint is responsible for 40% of our database load. We need a solution that:
    1. Eliminates the N+1 queries
    2. Works with pagination
    3. Doesn't require denormalization

    What's the recommended approach for eager loading polymorphic associations in Rails 7+?
  BODY
  answers: [
    {
      author: experts[2],
      body: <<~ANSWER,
        This is a well-known limitation of ActiveRecord's eager loading with polymorphic associations. Here are three approaches, ordered by complexity:

        **1. Manual Preloading (Simplest)**
        ```ruby
        def index
          @comments = Comment.includes(:user).recent.page(params[:page])

          # Group by commentable type and preload each
          @comments.group_by(&:commentable_type).each do |type, comments|
            klass = type.constantize
            ids = comments.map(&:commentable_id)
            records = klass.where(id: ids).index_by(&:id)

            comments.each do |comment|
              comment.association(:commentable).target = records[comment.commentable_id]
            end
          end
        end
        ```

        **2. Using `ActiveRecord::Associations::Preloader` (More Elegant)**
        ```ruby
        def preload_commentables(comments)
          comments.group_by(&:commentable_type).each do |type, grouped_comments|
            ActiveRecord::Associations::Preloader.new(
              records: grouped_comments,
              associations: :commentable
            ).call
          end
        end
        ```

        **3. The Delegated Type Pattern (Rails 6.1+)**
        If you can refactor, consider using delegated types instead:
        ```ruby
        class Comment < ApplicationRecord
          delegated_type :commentable, types: %w[Post Article Product]
        end
        ```

        This allows standard `includes(:commentable)` to work because the association is no longer truly polymorphic.

        For your specific case with 40% database load, I'd recommend option 2 with caching:
        ```ruby
        def index
          @comments = Comment.includes(:user).recent.page(params[:page])
          preload_commentables(@comments)
        end
        ```

        This reduced our similar endpoint's query count from 102 to 4 queries.
      ANSWER
      votes: 47,
      correct: true
    },
    {
      author: intermediates[0],
      body: <<~ANSWER,
        Have you tried the `activerecord-preload-poly` gem? It adds a `preload_polymorphic` method:

        ```ruby
        Comment.preload_polymorphic(:commentable).recent.page(params[:page])
        ```

        Works pretty well in our project.
      ANSWER
      votes: 12
    }
  ],
  created_ago: 15.days
)

# Intermediate Rails question
create_qa(
  category: rails_cat,
  author: intermediates[1],
  title: "Best practice for handling file uploads with Active Storage in Rails 7",
  body: <<~BODY,
    I'm building a feature where users can upload profile pictures. I'm using Active Storage but I'm not sure about best practices.

    Questions:
    1. Should I use `has_one_attached` or `has_many_attached`?
    2. How do I validate file size and type?
    3. What's the best way to handle image resizing?

    Here's my current model:
    ```ruby
    class User < ApplicationRecord
      has_one_attached :avatar
    end
    ```

    Any guidance would be appreciated!
  BODY
  answers: [
    {
      author: experts[3],
      body: <<~ANSWER,
        Great questions! Here's a comprehensive approach:

        **1. Use `has_one_attached` for single profile pictures**
        Your current setup is correct.

        **2. Validations with `active_storage_validations` gem**
        ```ruby
        # Gemfile
        gem 'active_storage_validations'

        # app/models/user.rb
        class User < ApplicationRecord
          has_one_attached :avatar

          validates :avatar,
            content_type: ['image/png', 'image/jpeg', 'image/webp'],
            size: { less_than: 5.megabytes }
        end
        ```

        **3. Image Processing with Variants**
        ```ruby
        class User < ApplicationRecord
          has_one_attached :avatar do |attachable|
            attachable.variant :thumb, resize_to_limit: [100, 100]
            attachable.variant :medium, resize_to_limit: [300, 300]
          end
        end

        # In views
        <%= image_tag user.avatar.variant(:thumb) %>
        ```

        **Bonus: Direct Uploads**
        For better UX, enable direct uploads:
        ```erb
        <%= form.file_field :avatar, direct_upload: true %>
        ```

        This uploads directly to your storage service, bypassing your Rails server.
      ANSWER
      votes: 23,
      correct: true
    }
  ],
  created_ago: 8.days
)

# Newbie Rails question (poorly phrased)
create_qa(
  category: rails_cat,
  author: newbies[0],
  title: "rails not working help plz",
  body: <<~BODY,
    hi im new to rails and i keep getting an error when i try to do stuff with my database

    it says something about migrations or something?? i tried googling but nothing works

    heres the error:
    ```
    ActiveRecord::PendingMigrationError
    ```

    how do i fix this??? been stuck for 2 hours already. any help appreciated thanks
  BODY
  answers: [
    {
      author: intermediates[2],
      body: <<~ANSWER,
        Welcome to Rails! This is a common error for beginners.

        The error means you have database migrations that haven't been run yet. Run this command in your terminal:

        ```bash
        rails db:migrate
        ```

        If that doesn't work, try:
        ```bash
        rails db:create db:migrate
        ```

        **What are migrations?**
        Migrations are Ruby files that describe changes to your database (creating tables, adding columns, etc.). Rails tracks which migrations have run, and this error means some haven't been applied yet.

        Pro tip: After pulling new code or switching branches, always run `rails db:migrate` to ensure your database is up to date.
      ANSWER
      votes: 8,
      correct: true
    },
    {
      author: newbies[1],
      body: <<~ANSWER,
        i had this same problem! running `rails db:migrate` fixed it for me too. good luck with learning rails :)
      ANSWER
      votes: 2
    }
  ],
  created_ago: 2.days
)

# -----------------------------------------------------------------------------
# JavaScript Questions
# -----------------------------------------------------------------------------

# Expert JS question
create_qa(
  category: js_cat,
  author: experts[1],
  title: "Understanding JavaScript event loop: Microtasks vs Macrotasks execution order",
  body: <<~BODY,
    I'm trying to understand the precise execution order of microtasks and macrotasks in the JavaScript event loop. Consider this code:

    ```javascript
    console.log('1');

    setTimeout(() => console.log('2'), 0);

    Promise.resolve().then(() => {
      console.log('3');
      setTimeout(() => console.log('4'), 0);
    }).then(() => console.log('5'));

    queueMicrotask(() => console.log('6'));

    console.log('7');
    ```

    I expected: 1, 7, 3, 5, 6, 2, 4
    But I got: 1, 7, 3, 6, 5, 2, 4

    Why does '6' appear before '5'? My understanding was that promise `.then()` callbacks and `queueMicrotask()` both go into the microtask queue and should execute in FIFO order.

    Can someone explain the exact ordering rules?
  BODY
  answers: [
    {
      author: experts[4],
      body: <<~ANSWER,
        Excellent question! The output `1, 7, 3, 6, 5, 2, 4` is actually correct. Here's why:

        **Key insight: Microtasks are processed after each task AND after each microtask.**

        Let's trace through:

        1. **Synchronous execution:**
           - `console.log('1')` → outputs **1**
           - `setTimeout` schedules macro task for '2'
           - `Promise.resolve().then(...)` schedules microtask A (for '3')
           - `queueMicrotask` schedules microtask B (for '6')
           - `console.log('7')` → outputs **7**

        2. **First microtask checkpoint (after sync code):**
           - Process microtask A: outputs **3**, schedules new setTimeout for '4', and chains `.then()` for '5'
           - ⚠️ **The `.then()` for '5' is scheduled NOW** (after '3' runs), so it goes to the END of the current microtask queue
           - Process microtask B: outputs **6**
           - Process the newly added microtask for '5': outputs **5**

        3. **Macrotask queue:**
           - Process setTimeout for '2': outputs **2**
           - Process setTimeout for '4': outputs **4**

        **The key rule:** When a microtask completes and schedules another microtask (like the chained `.then()`), that new microtask is added to the end of the current queue. But `queueMicrotask('6')` was already in the queue before the `.then('5')` was added!

        ```
        Initial microtask queue: [A(3), B(6)]
        After A runs: [B(6), then(5)]  ← then(5) added to END
        After B runs: [then(5)]
        After then(5): []
        ```
      ANSWER
      votes: 38,
      correct: true
    }
  ],
  created_ago: 22.days
)

# Intermediate JS question
create_qa(
  category: js_cat,
  author: intermediates[3],
  title: "How to properly debounce API calls in React with hooks?",
  body: <<~BODY,
    I'm building a search component that makes API calls as the user types. I want to debounce the calls to avoid hammering the server.

    Here's what I have:
    ```jsx
    function Search() {
      const [query, setQuery] = useState('');
      const [results, setResults] = useState([]);

      useEffect(() => {
        const fetchResults = async () => {
          const data = await api.search(query);
          setResults(data);
        };
        fetchResults();
      }, [query]);

      return (
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      );
    }
    ```

    This makes a request on every keystroke. How do I add debouncing properly with hooks?
  BODY
  answers: [
    {
      author: experts[2],
      body: <<~ANSWER,
        Here's a clean solution using a custom hook:

        ```jsx
        // useDebounce.js
        function useDebounce(value, delay) {
          const [debouncedValue, setDebouncedValue] = useState(value);

          useEffect(() => {
            const timer = setTimeout(() => setDebouncedValue(value), delay);
            return () => clearTimeout(timer);
          }, [value, delay]);

          return debouncedValue;
        }

        // Search.jsx
        function Search() {
          const [query, setQuery] = useState('');
          const [results, setResults] = useState([]);
          const debouncedQuery = useDebounce(query, 300);

          useEffect(() => {
            if (!debouncedQuery) return;

            const controller = new AbortController();

            api.search(debouncedQuery, { signal: controller.signal })
              .then(setResults)
              .catch(err => {
                if (err.name !== 'AbortError') throw err;
              });

            return () => controller.abort();
          }, [debouncedQuery]);

          return (
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
          );
        }
        ```

        Key improvements:
        1. **Custom `useDebounce` hook** - reusable across components
        2. **AbortController** - cancels in-flight requests when query changes
        3. **300ms delay** - good balance between responsiveness and server load

        You could also use `useDeferredValue` from React 18 for a simpler (but different) approach.
      ANSWER
      votes: 31,
      correct: true
    },
    {
      author: intermediates[4],
      body: <<~ANSWER,
        If you're using lodash, you can also do:

        ```jsx
        import { debounce } from 'lodash';

        const debouncedSearch = useMemo(
          () => debounce((q) => api.search(q).then(setResults), 300),
          []
        );

        useEffect(() => {
          debouncedSearch(query);
          return () => debouncedSearch.cancel();
        }, [query, debouncedSearch]);
        ```

        The custom hook approach above is cleaner though!
      ANSWER
      votes: 14
    }
  ],
  created_ago: 5.days
)

# Newbie JS question
create_qa(
  category: js_cat,
  author: newbies[2],
  title: "why does my variable say undefined?????",
  body: <<~BODY,
    so i have this code and it keeps saying undefined and i dont know why

    ```javascript
    function getData() {
      fetch('https://api.example.com/data')
        .then(response => response.json())
        .then(data => {
          return data;
        });
    }

    const result = getData();
    console.log(result);  // undefined!!!!
    ```

    i clearly return the data so why isnt it working?!?!
  BODY
  answers: [
    {
      author: intermediates[0],
      body: <<~ANSWER,
        This is one of the most common JavaScript gotchas! The issue is that `fetch` is **asynchronous**.

        When you call `getData()`, it starts the fetch but immediately returns `undefined` (because the function doesn't have a `return` statement at its top level).

        Here's how to fix it:

        **Option 1: Return the Promise**
        ```javascript
        function getData() {
          return fetch('https://api.example.com/data')  // Add return here!
            .then(response => response.json());
        }

        getData().then(result => {
          console.log(result);  // Now it works!
        });
        ```

        **Option 2: Use async/await (recommended)**
        ```javascript
        async function getData() {
          const response = await fetch('https://api.example.com/data');
          return response.json();
        }

        // Using it:
        const result = await getData();
        console.log(result);
        ```

        The key concept: `fetch` returns a Promise, which represents a value that will be available *in the future*. You can't treat it like synchronous code.
      ANSWER
      votes: 15,
      correct: true
    },
    {
      author: newbies[3],
      body: <<~ANSWER,
        omg i had this exact problem last week!! async stuff is so confusing at first but once you get it it makes sense. the answer above helped me too
      ANSWER
      votes: 3
    }
  ],
  created_ago: 1.day
)

# -----------------------------------------------------------------------------
# Python Questions
# -----------------------------------------------------------------------------

create_qa(
  category: python_cat,
  author: experts[1],
  title: "Type hints for decorators that preserve function signatures in Python 3.11+",
  body: <<~BODY,
    I'm struggling with properly typing a decorator that preserves the original function's signature. With Python 3.11+ and `ParamSpec`, I expected this to work:

    ```python
    from typing import Callable, ParamSpec, TypeVar
    from functools import wraps

    P = ParamSpec('P')
    R = TypeVar('R')

    def logged(func: Callable[P, R]) -> Callable[P, R]:
        @wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            print(f"Calling {func.__name__}")
            return func(*args, **kwargs)
        return wrapper

    @logged
    def greet(name: str, excited: bool = False) -> str:
        return f"Hello, {name}{'!' if excited else '.'}"
    ```

    But mypy still complains when I call `greet(123)` - it should catch that `123` isn't a string, but it doesn't.

    What am I missing with `ParamSpec`?
  BODY
  answers: [
    {
      author: experts[3],
      body: <<~ANSWER,
        Your decorator is actually correct! The issue is likely with your mypy configuration or version. Let me verify:

        ```python
        from typing import Callable, ParamSpec, TypeVar
        from functools import wraps

        P = ParamSpec('P')
        R = TypeVar('R')

        def logged(func: Callable[P, R]) -> Callable[P, R]:
            @wraps(func)
            def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
                print(f"Calling {func.__name__}")
                return func(*args, **kwargs)
            return wrapper

        @logged
        def greet(name: str, excited: bool = False) -> str:
            return f"Hello, {name}{'!' if excited else '.'}"

        # This SHOULD be an error
        greet(123)  # mypy: Argument 1 to "greet" has incompatible type "int"; expected "str"
        ```

        I tested with mypy 1.5+ and it correctly catches the error. Check:

        1. **mypy version**: `mypy --version` (need 0.950+ for full ParamSpec support)
        2. **Python version in config**: Make sure `python_version = "3.11"` in mypy.ini
        3. **Strict mode**: Try running with `mypy --strict`

        If you're using pyright/pylance instead, they have excellent ParamSpec support.

        **Common gotcha**: If you're testing in a REPL or notebook, type checkers don't run there - you need to run mypy on the actual file.
      ANSWER
      votes: 19,
      correct: true
    }
  ],
  created_ago: 18.days
)

# -----------------------------------------------------------------------------
# DevOps Questions
# -----------------------------------------------------------------------------

create_qa(
  category: devops_cat,
  author: intermediates[2],
  title: "Kubernetes pod keeps getting OOMKilled - how to debug memory issues?",
  body: <<~BODY,
    My Rails app pod keeps getting OOMKilled in Kubernetes. I've set memory limits but it keeps happening:

    ```yaml
    resources:
      requests:
        memory: "512Mi"
      limits:
        memory: "1Gi"
    ```

    The app works fine locally with similar memory usage. How do I debug what's consuming all the memory?

    Logs from `kubectl describe pod`:
    ```
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
    ```
  BODY
  answers: [
    {
      author: experts[4],
      body: <<~ANSWER,
        OOMKilled issues can be tricky. Here's a systematic debugging approach:

        **1. Check actual memory usage:**
        ```bash
        kubectl top pod <pod-name>
        kubectl exec -it <pod-name> -- cat /sys/fs/cgroup/memory/memory.usage_in_bytes
        ```

        **2. Enable memory profiling in Rails:**
        ```ruby
        # Gemfile
        gem 'memory_profiler'
        gem 'derailed_benchmarks'

        # Run locally:
        bundle exec derailed bundle:mem
        ```

        **3. Common culprits for Rails:**
        - **Puma workers**: Each worker consumes memory. If you have 4 workers × 300MB = 1.2GB
        - **Asset precompilation**: Can spike memory during startup
        - **Memory leaks**: Often from string interpolation in loops or unclosed connections

        **4. Quick fixes to try:**
        ```yaml
        env:
          - name: MALLOC_ARENA_MAX
            value: "2"  # Reduces glibc memory fragmentation
          - name: RAILS_MAX_THREADS
            value: "5"
          - name: WEB_CONCURRENCY
            value: "2"  # Reduce Puma workers
        ```

        **5. Use jemalloc:**
        ```dockerfile
        RUN apt-get install -y libjemalloc2
        ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
        ```

        Start with `MALLOC_ARENA_MAX=2` - it's a quick win that often reduces memory by 30-50%.
      ANSWER
      votes: 28,
      correct: true
    }
  ],
  created_ago: 10.days
)

# -----------------------------------------------------------------------------
# Database Questions
# -----------------------------------------------------------------------------

create_qa(
  category: categories.find { |c| c.slug == "databases" },
  author: intermediates[5],
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
      author: experts[0],
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

# -----------------------------------------------------------------------------
# Security Questions
# -----------------------------------------------------------------------------

create_qa(
  category: categories.find { |c| c.slug == "security" },
  author: intermediates[4],
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
      author: experts[2],
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
      correct: true
    }
  ],
  created_ago: 6.days
)

# -----------------------------------------------------------------------------
# Architecture Questions
# -----------------------------------------------------------------------------

create_qa(
  category: categories.find { |c| c.slug == "architecture" },
  author: experts[3],
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
      author: experts[0],
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

# -----------------------------------------------------------------------------
# Testing Questions
# -----------------------------------------------------------------------------

create_qa(
  category: categories.find { |c| c.slug == "testing" },
  author: intermediates[1],
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
      author: experts[2],
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

# Create a few more newbie questions for variety
create_qa(
  category: rails_cat,
  author: newbies[4],
  title: "what is the difference betwen render and redirect???",
  body: <<~BODY,
    hello i am learning rails and i dont understand when to use render and when to use redirect_to. my teacher said they are different but i dont get it

    can someone explain like im 5 lol. also my code doesnt work:

    ```ruby
    def create
      @post = Post.new(post_params)
      if @post.save
        render :show  # this doesnt work right
      end
    end
    ```
  BODY
  answers: [
    {
      author: moderators[0],
      body: <<~ANSWER,
        Welcome to Rails! This confuses everyone at first. Here's the simple explanation:

        **`render`** = "Show this view template using the current data"
        - Stays on the same URL
        - Keeps all your instance variables (`@post`)
        - Good for showing forms again with errors

        **`redirect_to`** = "Tell the browser to go to a different URL"
        - Changes the URL in the browser
        - Starts a completely new request
        - Loses all instance variables

        **For your code:**
        ```ruby
        def create
          @post = Post.new(post_params)
          if @post.save
            redirect_to @post  # ← Use redirect after successful save!
          else
            render :new  # ← Use render to show form again with errors
          end
        end
        ```

        **Why redirect after save?**
        If you use `render :show` after saving, and the user refreshes the page, they'll accidentally create another post! `redirect_to` prevents this (it's called the "Post-Redirect-Get" pattern).

        **Memory trick:**
        - 🔴 Something went **wrong** → `render` (stay here, show errors)
        - 🟢 Something went **right** → `redirect_to` (go somewhere else)
      ANSWER
      votes: 12,
      correct: true
    }
  ],
  created_ago: 3.days
)

puts "  Created questions and answers"

# =============================================================================
# Summary
# =============================================================================

puts ""
puts "Seeding complete!"
puts "================="
puts "Users: #{User.count}"
puts "  - Admins: #{User.admin.count}"
puts "  - Moderators: #{User.moderator.count}"
puts "  - Regular users: #{User.where(role: :user).count}"
puts "Categories: #{Category.count}"
puts "Category Moderators: #{CategoryModerator.count}"
puts "Questions: #{Question.count}"
puts "Answers: #{Answer.count}"
puts "Votes: #{Vote.count}"
