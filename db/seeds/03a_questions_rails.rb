# frozen_string_literal: true

# =============================================================================
# Questions and Answers - Ruby on Rails Space
# =============================================================================
puts "Creating Ruby on Rails questions..."

rails_space = Space.find_by!(slug: "ruby-on-rails")

# Expert-level Rails question
create_qa(
  space: rails_space,
  author: SEED_EXPERTS["dr.james.wilson@example.com"],
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
      author: SEED_EXPERTS["senior.dev.mike@example.com"],
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
      edited: true
    },
    {
      author: SEED_INTERMEDIATES["dev.ashley@example.com"],
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
  edited: true,
  edited_by: SEED_EXPERTS["dr.james.wilson@example.com"]
)

# Intermediate Rails question
create_qa(
  space: rails_space,
  author: SEED_INTERMEDIATES["coder.brian@example.com"],
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
      author: SEED_EXPERTS["architect.lisa@example.com"],
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
  space: rails_space,
  author: SEED_NEWBIES["newbie.henry@example.com"],
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
      author: SEED_INTERMEDIATES["fullstack.carol@example.com"],
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
      author: SEED_NEWBIES["student.ivy@example.com"],
      body: <<~ANSWER,
        i had this same problem! running `rails db:migrate` fixed it for me too. good luck with learning rails :)
      ANSWER
      votes: 2
    }
  ],
  created_ago: 2.days
)

# Newbie render vs redirect question
create_qa(
  space: rails_space,
  author: SEED_NEWBIES["first.timer.leo@example.com"],
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
      author: SEED_MODERATORS["sarah.chen@example.com"],
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

# Time zones question (SCENARIO 1: Top-voted NOT accepted)
create_qa(
  space: rails_space,
  author: SEED_INTERMEDIATES["dev.hannah@example.com"],
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
      author: SEED_INTERMEDIATES["coder.ian@example.com"],
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
      correct: false
    },
    {
      author: SEED_EXPERTS["staff.eng.nina@example.com"],
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
      correct: true
    },
    {
      author: SEED_INTERMEDIATES["fullstack.carol@example.com"],
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

# Newbie routes question
create_qa(
  space: rails_space,
  author: SEED_NEWBIES["learner.pedro@example.com"],
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
      author: SEED_MODERATORS["elena.rodriguez@example.com"],
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

puts "  Created Ruby on Rails questions"
