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
  u.full_name = "System Administrator"
  u.role = :admin
  u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=admin"
end

# Moderators
moderators = [
  { email: "sarah.chen@example.com", username: "sarahc", full_name: "Sarah Chen" },
  { email: "marcus.johnson@example.com", username: "mjohnson", full_name: "Marcus Johnson" },
  { email: "elena.rodriguez@example.com", username: "erodriguez", full_name: "Elena Rodriguez" }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.full_name = attrs[:full_name]
    u.role = :moderator
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Expert users (high activity, well-written questions/answers)
experts = [
  { email: "dr.james.wilson@example.com", username: "drjwilson", full_name: "Dr. James Wilson" },
  { email: "prof.aisha.patel@example.com", username: "apatel_prof", full_name: "Prof. Aisha Patel" },
  { email: "senior.dev.mike@example.com", username: "mike_seniordev", full_name: "Mike Thompson" },
  { email: "architect.lisa@example.com", username: "lisa_architect", full_name: "Lisa Chen" },
  { email: "principal.eng.tom@example.com", username: "tom_principal", full_name: "Tom Anderson" },
  { email: "staff.eng.nina@example.com", username: "nina_staff", full_name: "Nina Kozlov" },
  { email: "tech.lead.omar@example.com", username: "omar_techlead", full_name: "Omar Hassan" },
  { email: "senior.rachel@example.com", username: "rachel_senior", full_name: "Rachel Kim" },
  { email: "architect.sam@example.com", username: "sam_arch", full_name: "Sam Nakamura" },
  { email: "distinguished.eng@example.com", username: "victor_dist", full_name: "Victor Okonkwo" }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.full_name = attrs[:full_name]
    u.role = :user
    u.avatar_url = "https://api.dicebear.com/7.x/identicon/svg?seed=#{attrs[:username]}"
  end
end

# Intermediate users
intermediates = [
  { email: "dev.ashley@example.com", username: "ashley_dev", full_name: "Ashley Brooks" },
  { email: "coder.brian@example.com", username: "brian_codes", full_name: "Brian Chen" },
  { email: "fullstack.carol@example.com", username: "carol_fs", full_name: "Carol Davis" },
  { email: "backend.david@example.com", username: "david_backend", full_name: "David Evans" },
  { email: "frontend.emma@example.com", username: "emma_frontend", full_name: "Emma Foster" },
  { email: "junior.frank@example.com", username: "frank_jr" },
  { email: "learner.grace@example.com", username: "grace_learning" },
  { email: "dev.hannah@example.com", username: "hannah_dev", full_name: "Hannah Garcia" },
  { email: "coder.ian@example.com", username: "ian_codes", full_name: "Ian Hughes" },
  { email: "web.julia@example.com", username: "julia_web", full_name: "Julia Ivanova" },
  { email: "backend.kevin@example.com", username: "kevin_backend" },
  { email: "fullstack.laura@example.com", username: "laura_fs", full_name: "Laura Martinez" },
  { email: "dev.marcus@example.com", username: "marcus_dev", full_name: "Marcus Brown" },
  { email: "frontend.nadia@example.com", username: "nadia_frontend", full_name: "Nadia Shah" }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.full_name = attrs[:full_name]
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
  { email: "first.timer.leo@example.com", username: "leo_firsttime" },
  { email: "newdev.maya@example.com", username: "maya_newdev" },
  { email: "student.nathan@example.com", username: "nathan_student" },
  { email: "bootcamp.olivia@example.com", username: "olivia_bootcamp" },
  { email: "learner.pedro@example.com", username: "pedro_learns" },
  { email: "beginner.quinn@example.com", username: "quinn_beginner" }
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
  },
  # Empty categories (no questions yet)
  {
    name: "Rust",
    slug: "rust",
    description: "Questions about Rust programming language, memory safety, ownership, and systems programming."
  },
  {
    name: "Go",
    slug: "go",
    description: "Questions about Go (Golang), concurrency patterns, goroutines, and building scalable services."
  },
  {
    name: "Machine Learning",
    slug: "machine-learning",
    description: "Questions about ML algorithms, neural networks, training models, and AI applications."
  },
  {
    name: "Mobile Development",
    slug: "mobile-development",
    description: "Questions about iOS, Android, React Native, Flutter, and cross-platform mobile development."
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
def create_qa(category:, author:, title:, body:, answers:, created_ago: rand(1..90).days, edited: false, edited_by: nil)
  question = Question.find_or_create_by!(title: title) do |q|
    q.category = category
    q.user = author
    q.body = body
    q.created_at = created_ago.ago
    q.updated_at = created_ago.ago
  end

  # Mark question as edited if specified
  if edited && question.edited_at.nil?
    edit_time = (created_ago - rand(1..12).hours).ago
    question.update!(edited_at: edit_time, last_editor: edited_by || author)
  end

  answers.each_with_index do |answer_data, index|
    answer = Answer.find_or_create_by!(question: question, user: answer_data[:author]) do |a|
      a.body = answer_data[:body]
      a.vote_score = answer_data[:votes] || 0
      a.is_correct = answer_data[:correct] || false
      a.created_at = (created_ago - (index + 1).hours).ago
      a.updated_at = (created_ago - (index + 1).hours).ago
    end

    # Mark answer as edited if specified
    if answer_data[:edited] && answer.edited_at.nil?
      edit_time = (created_ago - (index + 1).hours - rand(1..6).hours).ago
      answer.update!(edited_at: edit_time, last_editor: answer_data[:edited_by] || answer_data[:author])
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
      correct: true,
      edited: true  # Answer was refined after initial post
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
  created_ago: 15.days,
  edited: true,  # Question was clarified after initial feedback
  edited_by: experts[0]
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
      correct: true,
      edited: true  # Added constant-time comparison note after feedback
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

# -----------------------------------------------------------------------------
# Additional Questions - demonstrating top-voted vs accepted answer scenarios
# -----------------------------------------------------------------------------

# SCENARIO 1: Top-voted answer is NOT accepted (popular but technically flawed)
# Moderator chose a less popular but more accurate answer
create_qa(
  category: rails_cat,
  author: intermediates[7],
  title: "How to handle time zones correctly in Rails applications?",
  body: <<~BODY,
    I'm building an app with users across multiple time zones. I'm confused about how to handle timestamps correctly.

    Should I store everything in UTC? How do I display times in the user's local timezone?

    Current setup:
    ```ruby
    config.time_zone = 'Eastern Time (US & Canada)'
    config.active_record.default_timezone = :utc
    ```

    Is this correct?
  BODY
  answers: [
    {
      author: intermediates[8],
      body: <<~ANSWER,
        Just use `Time.current` everywhere and Rails handles it automatically!

        ```ruby
        # Good
        Event.where('starts_at > ?', Time.current)

        # Display in user's zone
        event.starts_at.in_time_zone(current_user.time_zone)
        ```

        Easy peasy. The config you have is fine.
      ANSWER
      votes: 28,
      correct: false  # Popular but oversimplified
    },
    {
      author: experts[5],
      body: <<~ANSWER,
        Your config is correct - storing in UTC is the right approach. However, there are several important nuances:

        **1. Always use time zone aware methods:**
        ```ruby
        # Good
        Time.current
        Time.zone.now
        Time.zone.parse("2024-01-15 10:00")

        # Bad - bypasses time zone handling
        Time.now
        DateTime.now
        Date.today  # Be careful - has no time component
        ```

        **2. Database queries need care:**
        ```ruby
        # Dangerous - compares against server timezone
        Event.where("DATE(starts_at) = ?", Date.today)

        # Safe - explicit time range in app's timezone
        Event.where(starts_at: Time.current.beginning_of_day..Time.current.end_of_day)
        ```

        **3. User time zone handling:**
        ```ruby
        # In ApplicationController
        around_action :set_time_zone

        def set_time_zone
          Time.use_zone(current_user&.time_zone || 'UTC') { yield }
        end
        ```

        **4. Don't forget about date-only fields:**
        ```ruby
        # birthday is a DATE column - no time zone conversion
        # Be explicit about what you mean
        user.birthday  # Returns Date, not DateTime
        ```

        **5. Testing gotcha:**
        ```ruby
        # In spec_helper.rb
        config.around(:each) do |example|
          Time.use_zone('UTC') { example.run }
        end
        ```

        The first answer's approach works for simple cases but will bite you with date boundaries and edge cases.
      ANSWER
      votes: 15,
      correct: true  # Moderator chose this comprehensive answer
    },
    {
      author: intermediates[2],
      body: <<~ANSWER,
        I'd also recommend adding the `ActiveSupport::TimeZone` validation to ensure users pick valid zones:

        ```ruby
        validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
        ```

        We had a bug where users entered free text like "PST" which caused issues.
      ANSWER
      votes: 9,
      correct: false
    }
  ],
  created_ago: 7.days
)

# SCENARIO 2: Question with highly-voted answers but NO accepted answer yet
# (Moderator hasn't reviewed it)
create_qa(
  category: js_cat,
  author: intermediates[9],
  title: "Best state management solution for React in 2024?",
  body: <<~BODY,
    Starting a new React project and need to decide on state management. Options I'm considering:

    - Redux Toolkit
    - Zustand
    - Jotai
    - React Query + Context
    - Just useState/useContext

    What's the current consensus? We'll have ~50 components, some complex forms, and API data fetching.
  BODY
  answers: [
    {
      author: experts[6],
      body: <<~ANSWER,
        For your use case, I'd recommend **React Query + Zustand**:

        **React Query** for server state:
        ```jsx
        const { data, isLoading } = useQuery({
          queryKey: ['users'],
          queryFn: fetchUsers
        });
        ```

        **Zustand** for client state:
        ```jsx
        const useStore = create((set) => ({
          filters: {},
          setFilter: (key, value) => set((state) => ({
            filters: { ...state.filters, [key]: value }
          }))
        }));
        ```

        This combo is lightweight, has great DX, and separates concerns cleanly. Redux is overkill for most apps in 2024.
      ANSWER
      votes: 45,
      correct: false  # No accepted answer yet - this is top voted
    },
    {
      author: experts[7],
      body: <<~ANSWER,
        Controversial take: **just use React's built-in state**.

        With React 18's automatic batching and useSyncExternalStore, you often don't need external state management anymore.

        ```jsx
        // Context for auth/theme (rarely changes)
        const AuthContext = createContext();

        // Local state for forms
        const [formData, setFormData] = useState({});

        // React Query for server data
        const { data } = useQuery(['posts'], fetchPosts);
        ```

        Only add Zustand/Redux when you *actually* hit prop drilling issues. YAGNI applies to state management too.
      ANSWER
      votes: 32,
      correct: false
    },
    {
      author: intermediates[10],
      body: <<~ANSWER,
        We switched from Redux to Zustand last year and it was the best decision. Redux has too much boilerplate:

        ```jsx
        // Zustand - simple and clean
        const useCart = create((set) => ({
          items: [],
          addItem: (item) => set((s) => ({ items: [...s.items, item] })),
          clearCart: () => set({ items: [] })
        }));

        // Usage - no Provider needed!
        function Cart() {
          const items = useCart((s) => s.items);
          return <div>{items.length} items</div>;
        }
        ```

        Zero boilerplate, great TypeScript support, and tiny bundle size.
      ANSWER
      votes: 21,
      correct: false
    }
  ],
  created_ago: 3.days
)

# SCENARIO 3: Accepted answer with LOW votes (moderator knows the technically correct but unpopular answer)
create_qa(
  category: categories.find { |c| c.slug == "databases" },
  author: intermediates[11],
  title: "Should I use UUID or auto-increment for primary keys?",
  body: <<~BODY,
    New project, trying to decide between UUID and auto-increment integers for primary keys.

    We'll eventually have a distributed system with multiple databases. Does that affect the choice?

    PostgreSQL 15.
  BODY
  answers: [
    {
      author: intermediates[3],
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
      correct: false  # Popular but incomplete advice
    },
    {
      author: experts[8],
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
      correct: true  # Moderator chose the nuanced, technically accurate answer
    },
    {
      author: newbies[5],
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

# SCENARIO 4: Multiple high-voted answers, moderator chose middle-ground one
create_qa(
  category: categories.find { |c| c.slug == "security" },
  author: intermediates[12],
  title: "How to store API keys securely in a Rails application?",
  body: <<~BODY,
    I need to store third-party API keys (Stripe, SendGrid, etc.) for my Rails app.

    Currently using environment variables but wondering if there's a better way.

    What are the security best practices here?
  BODY
  answers: [
    {
      author: intermediates[1],
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
      correct: false  # Good but basic
    },
    {
      author: experts[9],
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
      correct: false  # Excellent but not complete for enterprise
    },
    {
      author: experts[5],
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
      correct: true  # Comprehensive, security-focused answer
    }
  ],
  created_ago: 9.days
)

# SCENARIO 5: Question with no accepted answer - all answers are partial solutions
create_qa(
  category: categories.find { |c| c.slug == "architecture" },
  author: experts[7],
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
      author: experts[0],
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
      correct: false  # Good advice but no definitive answer
    },
    {
      author: experts[8],
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
      correct: false  # Valid counterpoint but also opinionated
    },
    {
      author: intermediates[13],
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
      correct: false  # Real experience, valuable but no accepted answer
    }
  ],
  created_ago: 4.days
)

# More questions with varied scenarios
create_qa(
  category: python_cat,
  author: intermediates[8],
  title: "FastAPI vs Django REST Framework for new API project?",
  body: <<~BODY,
    Starting a new backend API project. Team has Django experience but FastAPI looks interesting.

    Requirements:
    - REST API with ~30 endpoints
    - PostgreSQL database
    - Background tasks
    - WebSocket support for notifications
    - OpenAPI documentation

    Which framework would you recommend and why?
  BODY
  answers: [
    {
      author: experts[6],
      body: <<~ANSWER,
        **FastAPI** for greenfield API-only projects:

        ```python
        from fastapi import FastAPI
        from pydantic import BaseModel

        app = FastAPI()

        class User(BaseModel):
            name: str
            email: str

        @app.post("/users")
        async def create_user(user: User):
            return {"id": 1, **user.dict()}
        ```

        **Pros:**
        - Native async support
        - Auto-generated OpenAPI docs
        - Pydantic validation is amazing
        - WebSockets built-in
        - 3-5x faster than DRF

        **Cons:**
        - Less mature ecosystem
        - No built-in ORM (use SQLAlchemy)
        - Smaller community

        For your use case with WebSocket requirement, FastAPI is the better choice.
      ANSWER
      votes: 42,
      correct: false  # Popular but one-sided
    },
    {
      author: experts[9],
      body: <<~ANSWER,
        Given your **team has Django experience**, I'd lean toward **Django REST Framework**:

        **DRF advantages:**
        - Team productivity from day one
        - Battle-tested at massive scale
        - Rich ecosystem (permissions, filtering, pagination)
        - Django ORM is mature and well-understood

        **For your requirements:**
        - REST endpoints: DRF excels here
        - PostgreSQL: Django ORM is excellent
        - Background tasks: Celery integrates seamlessly
        - WebSockets: Django Channels works fine
        - OpenAPI: drf-spectacular generates great docs

        ```python
        # DRF is very productive
        class UserViewSet(viewsets.ModelViewSet):
            queryset = User.objects.all()
            serializer_class = UserSerializer
            permission_classes = [IsAuthenticated]
            filter_backends = [DjangoFilterBackend]
        ```

        FastAPI is great, but the learning curve + building from scratch (auth, permissions, etc.) will cost you 2-3 months.
      ANSWER
      votes: 28,
      correct: true  # Moderator chose the pragmatic team-focused answer
    }
  ],
  created_ago: 6.days
)

create_qa(
  category: categories.find { |c| c.slug == "testing" },
  author: intermediates[10],
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
      author: experts[2],
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
      author: experts[4],
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
      correct: false  # Highest voted, valid but absolute
    },
    {
      author: moderators[0],
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
      correct: true  # Balanced, practical answer
    }
  ],
  created_ago: 8.days
)

# DevOps question with no accepted answer (legitimate disagreement)
create_qa(
  category: devops_cat,
  author: intermediates[12],
  title: "Kubernetes vs Docker Compose for small team - is K8s overkill?",
  body: <<~BODY,
    We're a team of 5 developers running 3 microservices. Currently using Docker Compose in production on a single server.

    Getting pressure to move to Kubernetes for "scalability" but I'm skeptical.

    Is K8s worth the complexity for a small team? What's the break-even point?
  BODY
  answers: [
    {
      author: experts[4],
      body: <<~ANSWER,
        **Kubernetes is overkill for you.** Here's the reality check:

        **K8s complexity:**
        - 2-3 months to learn properly
        - YAML hell (100s of lines for simple apps)
        - Networking is dark magic
        - Debugging is 10x harder
        - Need dedicated DevOps or pay for managed K8s

        **What you actually need for 3 services:**
        ```yaml
        # docker-compose.prod.yml
        services:
          app:
            image: myapp:latest
            deploy:
              replicas: 2
              update_config:
                parallelism: 1
                delay: 10s
          worker:
            image: myworker:latest
        ```

        Docker Swarm (built into Docker) gives you:
        - Service discovery
        - Rolling deploys
        - Basic load balancing
        - Secrets management

        Move to K8s when: 20+ services, multiple teams, need advanced networking, or compliance requires it.
      ANSWER
      votes: 38,
      correct: false
    },
    {
      author: experts[7],
      body: <<~ANSWER,
        Disagree with the "K8s is overkill" crowd. **Managed Kubernetes is very accessible:**

        ```bash
        # GKE Autopilot - fully managed
        gcloud container clusters create-auto my-cluster

        # Deploy your app
        kubectl apply -f deployment.yaml
        ```

        **Why K8s even for small teams:**
        - Industry standard (transferable skills)
        - Helm charts = instant PostgreSQL, Redis, etc.
        - Auto-scaling, self-healing built-in
        - Cost optimization (node autoscaling)
        - Better security defaults

        **The real question:** Can you afford a $200-400/month managed K8s cluster? If yes, it's worth it for the operational benefits.

        Don't run K8s yourself though. GKE Autopilot, EKS Fargate, or DigitalOcean Kubernetes.
      ANSWER
      votes: 31,
      correct: false
    }
  ],
  created_ago: 5.days
)

# Question with ONLY a newbie answer (no expert response yet)
create_qa(
  category: js_cat,
  author: newbies[6],
  title: "How to loop through an array in JavaScript?",
  body: <<~BODY,
    how do i loop through an array? i tried this but it doesnt work

    ```javascript
    for (let i = 0; i < arr; i++) {
      console.log(arr[i]);
    }
    ```

    it says arr is not a number or something??
  BODY
  answers: [
    {
      author: newbies[7],
      body: <<~ANSWER,
        you need arr.length not arr!!

        ```javascript
        for (let i = 0; i < arr.length; i++) {
          console.log(arr[i]);
        }
        ```

        i made the same mistake lol
      ANSWER
      votes: 3,
      correct: true  # Correct despite being from a newbie
    },
    {
      author: intermediates[0],
      body: <<~ANSWER,
        The fix above is correct. Here are all the ways to loop arrays in modern JS:

        ```javascript
        const arr = [1, 2, 3];

        // Classic for loop
        for (let i = 0; i < arr.length; i++) {
          console.log(arr[i]);
        }

        // for...of (recommended for most cases)
        for (const item of arr) {
          console.log(item);
        }

        // forEach
        arr.forEach(item => console.log(item));

        // map (when you need to transform)
        const doubled = arr.map(x => x * 2);
        ```

        Use `for...of` unless you specifically need the index.
      ANSWER
      votes: 12,
      correct: false  # More comprehensive but newbie's answer was accepted first
    }
  ],
  created_ago: 1.day
)

# More variety - newbie question with expert help
create_qa(
  category: rails_cat,
  author: newbies[8],
  title: "Why does my Rails app say 'No route matches'?",
  body: <<~BODY,
    im trying to make a page but it keeps saying

    No route matches [GET] "/users/profile"

    i have this in my controller:
    ```ruby
    class UsersController < ApplicationController
      def profile
        @user = current_user
      end
    end
    ```

    what am i doing wrong?? the file is definitely there
  BODY
  answers: [
    {
      author: moderators[2],
      body: <<~ANSWER,
        You need to add the route in `config/routes.rb`! Rails doesn't automatically create routes.

        ```ruby
        # config/routes.rb
        Rails.application.routes.draw do
          get 'users/profile', to: 'users#profile'

          # Or if you want it at /profile
          get 'profile', to: 'users#profile'
        end
        ```

        After adding, run `rails routes` to see all your available routes:
        ```bash
        rails routes | grep profile
        ```

        Common mistake for beginners - unlike some frameworks, Rails requires explicit route definitions.
      ANSWER
      votes: 8,
      correct: true
    }
  ],
  created_ago: 12.hours
)

# High quality question with split community opinion
create_qa(
  category: categories.find { |c| c.slug == "architecture" },
  author: experts[6],
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
      author: experts[8],
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
      author: experts[9],
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

        ```yaml
        # renovate.json in each repo
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

puts "  Created questions and answers"

# =============================================================================
# Questions Without Answers (unanswered)
# =============================================================================
puts "Creating unanswered questions..."

unanswered_questions = []

# Recent unanswered question - expert level
unanswered_questions << Question.find_or_create_by!(
  title: "How to implement rate limiting with Redis in a distributed Rails environment?"
) do |q|
  q.category = rails_cat
  q.user = intermediates[3]
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
  q.category = js_cat
  q.user = newbies[1]
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
  q.category = rails_cat
  q.user = intermediates[5]
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
  q.category = categories.find { |c| c.slug == "testing" }
  q.user = intermediates[0]
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
  q.category = categories.find { |c| c.slug == "databases" }
  q.user = experts[4]
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
  q.category = rails_cat
  q.user = intermediates[7]
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
  q.category = categories.find { |c| c.slug == "security" }
  q.user = intermediates[9]
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
  q.category = categories.find { |c| c.slug == "architecture" }
  q.user = intermediates[11]
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
  q.category = js_cat
  q.user = newbies[9]
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
  q.category = devops_cat
  q.user = intermediates[10]
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

# =============================================================================
# Comments on Questions and Answers
# =============================================================================
puts "Creating comments..."

# Helper to create a comment
def create_comment(commentable:, author:, body:, created_ago: rand(1..48).hours, vote_score: 0, edited: false, edited_by: nil)
  comment = Comment.find_or_create_by!(commentable: commentable, user: author, body: body) do |c|
    c.vote_score = vote_score
    c.created_at = created_ago.ago
    c.updated_at = created_ago.ago
  end

  # Mark comment as edited if specified
  if edited && comment.edited_at.nil?
    edit_time = (created_ago - rand(1..6).hours).ago
    comment.update!(edited_at: edit_time, last_editor: edited_by || author)
  end

  comment
end

# Helper to create a reply comment
def create_reply(parent:, author:, body:, created_ago: nil, vote_score: 0, edited: false, edited_by: nil)
  created_ago ||= (parent.created_at - rand(1..12).hours.ago.to_i).seconds
  comment = Comment.find_or_create_by!(
    commentable: parent.commentable,
    user: author,
    parent_comment: parent,
    body: body
  ) do |c|
    c.vote_score = vote_score
    c.created_at = created_ago.ago
    c.updated_at = created_ago.ago
  end

  # Mark comment as edited if specified
  if edited && comment.edited_at.nil?
    edit_time = (created_ago - rand(1..3).hours).ago
    comment.update!(edited_at: edit_time, last_editor: edited_by || author)
  end

  comment
end

# Get some questions to add comments to
rails_polymorphic_q = Question.find_by(title: "Optimizing N+1 queries in complex ActiveRecord associations with polymorphic relationships")
js_event_loop_q = Question.find_by(title: "Understanding JavaScript event loop: Microtasks vs Macrotasks execution order")
newbie_rails_q = Question.find_by(title: "rails not working help plz")
debounce_q = Question.find_by(title: "How to properly debounce API calls in React with hooks?")
rate_limit_q = Question.find_by(title: "How to implement rate limiting with Redis in a distributed Rails environment?")

if rails_polymorphic_q
  # Comments on the N+1 question
  c1 = create_comment(
    commentable: rails_polymorphic_q,
    author: intermediates[1],
    body: "Have you considered using GraphQL with dataloader? It handles batching automatically.",
    created_ago: 14.days,
    vote_score: 3
  )

  c2 = create_comment(
    commentable: rails_polymorphic_q,
    author: experts[0],
    body: "Good question! For context, what's your average response time currently and what's your target?",
    created_ago: 14.days + 2.hours,
    vote_score: 1
  )

  # Reply to first comment
  c1_reply1 = create_reply(
    parent: c1,
    author: experts[2],
    body: "GraphQL dataloader is great but adds significant complexity. For a Rails app, the manual preloading approach is usually simpler.",
    created_ago: 13.days,
    vote_score: 5
  )

  # Nested reply (depth 2)
  create_reply(
    parent: c1_reply1,
    author: intermediates[1],
    body: "Fair point. We're actually considering migrating to GraphQL anyway, so it might be worth it for us.",
    created_ago: 13.days - 4.hours,
    vote_score: 2
  )

  # Another reply to original comment
  create_reply(
    parent: c1,
    author: newbies[2],
    body: "What's GraphQL? Is it better than REST?",
    created_ago: 12.days,
    vote_score: 0
  )

  # Comments on the accepted answer
  correct_answer = rails_polymorphic_q.answers.find_by(is_correct: true)
  if correct_answer
    ac1 = create_comment(
      commentable: correct_answer,
      author: intermediates[3],
      body: "The delegated types approach is really elegant! Didn't know about this Rails 6.1 feature.",
      created_ago: 14.days - 6.hours,
      vote_score: 8
    )

    create_comment(
      commentable: correct_answer,
      author: experts[1],
      body: "Note: `ActiveRecord::Associations::Preloader` is considered semi-private API. It works but might change in future Rails versions.",
      created_ago: 13.days,
      vote_score: 12,
      edited: true  # Clarified the API stability note
    )

    create_reply(
      parent: ac1,
      author: experts[2],
      body: "Yes! Delegated types are underrated. The trade-off is you need to add STI-like columns but it's worth it for the query simplicity.",
      created_ago: 13.days - 8.hours,
      vote_score: 4
    )
  end
end

if js_event_loop_q
  # Comments on JS event loop question
  c1 = create_comment(
    commentable: js_event_loop_q,
    author: intermediates[4],
    body: "This is a great question for interviews! I always get tripped up on microtask ordering.",
    created_ago: 21.days,
    vote_score: 6,
    edited: true  # Fixed typo
  )

  c2 = create_comment(
    commentable: js_event_loop_q,
    author: experts[3],
    body: "For anyone wanting to visualize this, check out Loupe (latentflip.com/loupe) - it's an amazing event loop visualizer.",
    created_ago: 20.days,
    vote_score: 15
  )

  create_reply(
    parent: c2,
    author: newbies[0],
    body: "That tool is incredible! Finally understanding how callbacks work. Thanks for sharing!",
    created_ago: 19.days,
    vote_score: 3
  )

  # Deep nested thread on the answer
  answer = js_event_loop_q.answers.first
  if answer
    ac1 = create_comment(
      commentable: answer,
      author: intermediates[2],
      body: "Wait, so queueMicrotask and Promise.then both go to the microtask queue, but the order depends on when they're scheduled?",
      created_ago: 21.days,
      vote_score: 4
    )

    ac1_r1 = create_reply(
      parent: ac1,
      author: experts[4],
      body: "Exactly! Both go to the same queue, processed FIFO. The key is *when* they get added to the queue.",
      created_ago: 21.days - 2.hours,
      vote_score: 7
    )

    ac1_r1_r1 = create_reply(
      parent: ac1_r1,
      author: intermediates[2],
      body: "So in the example, queueMicrotask('6') is added during sync execution, but .then('5') is added when the first .then('3') resolves?",
      created_ago: 21.days - 4.hours,
      vote_score: 2
    )

    ac1_r1_r1_r1 = create_reply(
      parent: ac1_r1_r1,
      author: experts[4],
      body: "You got it! That's exactly why 6 comes before 5. The .then('5') callback doesn't exist until '3' runs and returns.",
      created_ago: 21.days - 5.hours,
      vote_score: 9
    )

    # Another branch
    create_reply(
      parent: ac1_r1,
      author: newbies[3],
      body: "My brain hurts reading this but I think I'm starting to get it...",
      created_ago: 20.days,
      vote_score: 11
    )
  end
end

if newbie_rails_q
  # Encouraging comments on newbie question
  create_comment(
    commentable: newbie_rails_q,
    author: moderators[0],
    body: "Pro tip for next time: include the full error message and what you've already tried. It helps us help you faster!",
    created_ago: 1.day,
    vote_score: 5
  )

  correct_answer = newbie_rails_q.answers.find_by(is_correct: true)
  if correct_answer
    c1 = create_comment(
      commentable: correct_answer,
      author: newbies[0],
      body: "THANK YOU!!! it worked!! i feel so dumb now lol",
      created_ago: 1.day - 1.hour,
      vote_score: 2
    )

    create_reply(
      parent: c1,
      author: intermediates[2],
      body: "Don't feel dumb - we all started somewhere! This error trips up everyone at first.",
      created_ago: 1.day - 2.hours,
      vote_score: 8
    )
  end
end

if debounce_q
  # Technical discussion in comments
  c1 = create_comment(
    commentable: debounce_q,
    author: experts[1],
    body: "Consider also adding a minimum query length check to avoid API calls for very short queries.",
    created_ago: 4.days,
    vote_score: 7
  )

  correct_answer = debounce_q.answers.find_by(is_correct: true)
  if correct_answer
    ac1 = create_comment(
      commentable: correct_answer,
      author: intermediates[0],
      body: "Why use AbortController instead of just ignoring stale responses?",
      created_ago: 4.days - 3.hours,
      vote_score: 3
    )

    ac1_r1 = create_reply(
      parent: ac1,
      author: experts[2],
      body: "AbortController actually cancels the HTTP request, saving bandwidth and server resources. Ignoring responses still completes the request.",
      created_ago: 4.days - 5.hours,
      vote_score: 11,
      edited: true  # Added detail about bandwidth savings
    )

    create_reply(
      parent: ac1_r1,
      author: intermediates[0],
      body: "Ah that makes sense! Especially important for mobile users on slow connections.",
      created_ago: 4.days - 6.hours,
      vote_score: 2
    )

    create_comment(
      commentable: correct_answer,
      author: intermediates[5],
      body: "For React 18 users: useDeferredValue is great for this use case and handles the complexity for you.",
      created_ago: 3.days,
      vote_score: 6
    )
  end
end

if rate_limit_q
  # Comments on unanswered question
  c1 = create_comment(
    commentable: rate_limit_q,
    author: experts[2],
    body: "For the race condition, look into Redis MULTI/EXEC or Lua scripts. The sliding window algorithm is more accurate but harder to implement.",
    created_ago: 3.hours,
    vote_score: 4
  )

  c2 = create_comment(
    commentable: rate_limit_q,
    author: moderators[1],
    body: "Have you looked at the rack-attack gem? It handles most of these edge cases.",
    created_ago: 2.hours,
    vote_score: 2
  )

  create_reply(
    parent: c1,
    author: intermediates[3],
    body: "Can you elaborate on the Lua script approach? I've heard it's more atomic but haven't implemented one before.",
    created_ago: 1.hour,
    vote_score: 1
  )

  create_reply(
    parent: c2,
    author: intermediates[3],
    body: "I looked at rack-attack but wasn't sure how it handles the distributed case with multiple servers. Does it coordinate through Redis automatically?",
    created_ago: 30.minutes,
    vote_score: 0
  )
end

# Add comments to some other questions
security_q = Question.find_by(title: "How to properly implement password reset tokens in Rails?")
if security_q
  correct_answer = security_q.answers.find_by(is_correct: true)
  if correct_answer
    c1 = create_comment(
      commentable: correct_answer,
      author: intermediates[4],
      body: "What about using has_secure_token built into Rails? Does it hash by default?",
      created_ago: 5.days,
      vote_score: 4
    )

    create_reply(
      parent: c1,
      author: experts[2],
      body: "has_secure_token stores the raw token, which is fine for API tokens but NOT for password resets. Always hash reset tokens.",
      created_ago: 5.days - 2.hours,
      vote_score: 14
    )
  end
end

# Add comment vote scores to make some comments stand out
Comment.order("RANDOM()").limit(10).each do |comment|
  upvoters = User.where.not(id: comment.user_id).sample(rand(1..5))
  upvoters.each do |voter|
    CommentVote.find_or_create_by!(comment: comment, user: voter)
  end
  comment.update!(vote_score: comment.comment_votes.count)
end

puts "  Created #{Comment.count} comments (including #{Comment.where.not(parent_comment_id: nil).count} replies)"

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
puts "  - With questions: #{Category.joins(:questions).distinct.count}"
puts "  - Empty (no questions): #{Category.left_joins(:questions).where(questions: { id: nil }).count}"
puts "Category Moderators: #{CategoryModerator.count}"
puts "Questions: #{Question.count}"
puts "  - With answers: #{Question.joins(:answers).distinct.count}"
puts "  - Unanswered: #{Question.left_joins(:answers).where(answers: { id: nil }).count}"
puts "  - Edited: #{Question.where.not(edited_at: nil).count}"
puts "Answers: #{Answer.count}"
puts "  - Solved: #{Answer.where(is_correct: true).count}"
puts "  - Edited: #{Answer.where.not(edited_at: nil).count}"
puts "Votes: #{Vote.count}"
puts "Comments: #{Comment.count}"
puts "  - On questions: #{Comment.where(commentable_type: 'Question').count}"
puts "  - On answers: #{Comment.where(commentable_type: 'Answer').count}"
puts "  - Top-level: #{Comment.where(parent_comment_id: nil).count}"
puts "  - Replies: #{Comment.where.not(parent_comment_id: nil).count}"
puts "  - Edited: #{Comment.where.not(edited_at: nil).count}"
puts "Comment Votes: #{CommentVote.count}"
