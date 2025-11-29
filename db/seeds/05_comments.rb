# frozen_string_literal: true

# =============================================================================
# Comments on Questions and Answers
# =============================================================================
puts "Creating comments..."

# Use shared user lookups from 03_questions_header.rb (SEED_EXPERTS, SEED_INTERMEDIATES, SEED_NEWBIES, SEED_MODERATORS)

# Shared helper to mark a comment as edited
def mark_comment_as_edited(comment:, created_ago:, author:, edited_by: nil, hours_range: 1..6)
  return unless comment.edited_at.nil?

  edit_time = (created_ago - rand(hours_range).hours).ago
  comment.update!(edited_at: edit_time, last_editor: edited_by || author)
end

# Helper to create a comment
def seed_comment(commentable:, author:, body:, created_ago: rand(1..48).hours, vote_score: 0, edited: false, edited_by: nil)
  comment = Comment.find_or_create_by!(commentable: commentable, user: author, body: body) do |c|
    c.vote_score = vote_score
    c.created_at = created_ago.ago
    c.updated_at = created_ago.ago
  end

  mark_comment_as_edited(comment: comment, created_ago: created_ago, author: author, edited_by: edited_by) if edited

  comment
end

# Helper to create a reply comment
def seed_reply(parent:, author:, body:, created_ago: nil, vote_score: 0, edited: false, edited_by: nil)
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

  mark_comment_as_edited(comment: comment, created_ago: created_ago, author: author, edited_by: edited_by, hours_range: 1..3) if edited

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
  c1 = seed_comment(
    commentable: rails_polymorphic_q,
    author: SEED_INTERMEDIATES["coder.brian@example.com"],
    body: "Have you considered using GraphQL with dataloader? It handles batching automatically.",
    created_ago: 14.days,
    vote_score: 3
  )

  c2 = seed_comment(
    commentable: rails_polymorphic_q,
    author: SEED_EXPERTS["dr.james.wilson@example.com"],
    body: "Good question! For context, what's your average response time currently and what's your target?",
    created_ago: 14.days + 2.hours,
    vote_score: 1
  )

  # Reply to first comment
  c1_reply1 = seed_reply(
    parent: c1,
    author: SEED_EXPERTS["senior.dev.mike@example.com"],
    body: "GraphQL dataloader is great but adds significant complexity. For a Rails app, the manual preloading approach is usually simpler.",
    created_ago: 13.days,
    vote_score: 5
  )

  # Nested reply (depth 2)
  seed_reply(
    parent: c1_reply1,
    author: SEED_INTERMEDIATES["coder.brian@example.com"],
    body: "Fair point. We're actually considering migrating to GraphQL anyway, so it might be worth it for us.",
    created_ago: 13.days - 4.hours,
    vote_score: 2
  )

  # Another reply to original comment
  seed_reply(
    parent: c1,
    author: SEED_NEWBIES["beginner.jack@example.com"],
    body: "What's GraphQL? Is it better than REST?",
    created_ago: 12.days,
    vote_score: 0
  )

  # Comments on the accepted answer
  correct_answer = rails_polymorphic_q.answers.find_by(is_correct: true)
  if correct_answer
    ac1 = seed_comment(
      commentable: correct_answer,
      author: SEED_INTERMEDIATES["backend.david@example.com"],
      body: "The delegated types approach is really elegant! Didn't know about this Rails 6.1 feature.",
      created_ago: 14.days - 6.hours,
      vote_score: 8
    )

    seed_comment(
      commentable: correct_answer,
      author: SEED_EXPERTS["prof.aisha.patel@example.com"],
      body: "Note: `ActiveRecord::Associations::Preloader` is considered semi-private API. It works but might change in future Rails versions.",
      created_ago: 13.days,
      vote_score: 12,
      edited: true
    )

    seed_reply(
      parent: ac1,
      author: SEED_EXPERTS["senior.dev.mike@example.com"],
      body: "Yes! Delegated types are underrated. The trade-off is you need to add STI-like columns but it's worth it for the query simplicity.",
      created_ago: 13.days - 8.hours,
      vote_score: 4
    )
  end
end

if js_event_loop_q
  # Comments on JS event loop question
  c1 = seed_comment(
    commentable: js_event_loop_q,
    author: SEED_INTERMEDIATES["frontend.emma@example.com"],
    body: "This is a great question for interviews! I always get tripped up on microtask ordering.",
    created_ago: 21.days,
    vote_score: 6,
    edited: true
  )

  c2 = seed_comment(
    commentable: js_event_loop_q,
    author: SEED_EXPERTS["architect.lisa@example.com"],
    body: "For anyone wanting to visualize this, check out Loupe (latentflip.com/loupe) - it's an amazing event loop visualizer.",
    created_ago: 20.days,
    vote_score: 15
  )

  seed_reply(
    parent: c2,
    author: SEED_NEWBIES["newbie.henry@example.com"],
    body: "That tool is incredible! Finally understanding how callbacks work. Thanks for sharing!",
    created_ago: 19.days,
    vote_score: 3
  )

  # Deep nested thread on the answer
  answer = js_event_loop_q.answers.first
  if answer
    ac1 = seed_comment(
      commentable: answer,
      author: SEED_INTERMEDIATES["fullstack.carol@example.com"],
      body: "Wait, so queueMicrotask and Promise.then both go to the microtask queue, but the order depends on when they're scheduled?",
      created_ago: 21.days,
      vote_score: 4
    )

    ac1_r1 = seed_reply(
      parent: ac1,
      author: SEED_EXPERTS["principal.eng.tom@example.com"],
      body: "Exactly! Both go to the same queue, processed FIFO. The key is *when* they get added to the queue.",
      created_ago: 21.days - 2.hours,
      vote_score: 7
    )

    ac1_r1_r1 = seed_reply(
      parent: ac1_r1,
      author: SEED_INTERMEDIATES["fullstack.carol@example.com"],
      body: "So in the example, queueMicrotask('6') is added during sync execution, but .then('5') is added when the first .then('3') resolves?",
      created_ago: 21.days - 4.hours,
      vote_score: 2
    )

    seed_reply(
      parent: ac1_r1_r1,
      author: SEED_EXPERTS["principal.eng.tom@example.com"],
      body: "You got it! That's exactly why 6 comes before 5. The .then('5') callback doesn't exist until '3' runs and returns.",
      created_ago: 21.days - 5.hours,
      vote_score: 9
    )

    # Another branch
    seed_reply(
      parent: ac1_r1,
      author: SEED_NEWBIES["learning.kate@example.com"],
      body: "My brain hurts reading this but I think I'm starting to get it...",
      created_ago: 20.days,
      vote_score: 11
    )
  end
end

if newbie_rails_q
  # Encouraging comments on newbie question
  seed_comment(
    commentable: newbie_rails_q,
    author: SEED_MODERATORS["sarah.chen@example.com"],
    body: "Pro tip for next time: include the full error message and what you've already tried. It helps us help you faster!",
    created_ago: 1.day,
    vote_score: 5
  )

  correct_answer = newbie_rails_q.answers.find_by(is_correct: true)
  if correct_answer
    c1 = seed_comment(
      commentable: correct_answer,
      author: SEED_NEWBIES["newbie.henry@example.com"],
      body: "THANK YOU!!! it worked!! i feel so dumb now lol",
      created_ago: 1.day - 1.hour,
      vote_score: 2
    )

    seed_reply(
      parent: c1,
      author: SEED_INTERMEDIATES["fullstack.carol@example.com"],
      body: "Don't feel dumb - we all started somewhere! This error trips up everyone at first.",
      created_ago: 1.day - 2.hours,
      vote_score: 8
    )
  end
end

if debounce_q
  # Technical discussion in comments
  seed_comment(
    commentable: debounce_q,
    author: SEED_EXPERTS["prof.aisha.patel@example.com"],
    body: "Consider also adding a minimum query length check to avoid API calls for very short queries.",
    created_ago: 4.days,
    vote_score: 7
  )

  correct_answer = debounce_q.answers.find_by(is_correct: true)
  if correct_answer
    ac1 = seed_comment(
      commentable: correct_answer,
      author: SEED_INTERMEDIATES["dev.ashley@example.com"],
      body: "Why use AbortController instead of just ignoring stale responses?",
      created_ago: 4.days - 3.hours,
      vote_score: 3
    )

    ac1_r1 = seed_reply(
      parent: ac1,
      author: SEED_EXPERTS["senior.dev.mike@example.com"],
      body: "AbortController actually cancels the HTTP request, saving bandwidth and server resources. Ignoring responses still completes the request.",
      created_ago: 4.days - 5.hours,
      vote_score: 11,
      edited: true
    )

    seed_reply(
      parent: ac1_r1,
      author: SEED_INTERMEDIATES["dev.ashley@example.com"],
      body: "Ah that makes sense! Especially important for mobile users on slow connections.",
      created_ago: 4.days - 6.hours,
      vote_score: 2
    )

    seed_comment(
      commentable: correct_answer,
      author: SEED_INTERMEDIATES["junior.frank@example.com"],
      body: "For React 18 users: useDeferredValue is great for this use case and handles the complexity for you.",
      created_ago: 3.days,
      vote_score: 6
    )
  end
end

if rate_limit_q
  # Comments on unanswered question
  c1 = seed_comment(
    commentable: rate_limit_q,
    author: SEED_EXPERTS["senior.dev.mike@example.com"],
    body: "For the race condition, look into Redis MULTI/EXEC or Lua scripts. The sliding window algorithm is more accurate but harder to implement.",
    created_ago: 3.hours,
    vote_score: 4
  )

  c2 = seed_comment(
    commentable: rate_limit_q,
    author: SEED_MODERATORS["marcus.johnson@example.com"],
    body: "Have you looked at the rack-attack gem? It handles most of these edge cases.",
    created_ago: 2.hours,
    vote_score: 2
  )

  seed_reply(
    parent: c1,
    author: SEED_INTERMEDIATES["backend.david@example.com"],
    body: "Can you elaborate on the Lua script approach? I've heard it's more atomic but haven't implemented one before.",
    created_ago: 1.hour,
    vote_score: 1
  )

  seed_reply(
    parent: c2,
    author: SEED_INTERMEDIATES["backend.david@example.com"],
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
    c1 = seed_comment(
      commentable: correct_answer,
      author: SEED_INTERMEDIATES["frontend.emma@example.com"],
      body: "What about using has_secure_token built into Rails? Does it hash by default?",
      created_ago: 5.days,
      vote_score: 4
    )

    seed_reply(
      parent: c1,
      author: SEED_EXPERTS["senior.dev.mike@example.com"],
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
