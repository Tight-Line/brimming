# frozen_string_literal: true

# Shared constants and helpers for seed files
# This file is loaded first (00_) to make helpers available to other seed files

# Default password for all seed users (development only!)
DEFAULT_PASSWORD = "password123"

# Helper to create a question with answers and votes
def create_qa(space:, author:, title:, body:, answers:, created_ago: rand(1..90).days, edited: false, edited_by: nil)
  question = Question.find_or_create_by!(title: title) do |q|
    q.space = space
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

# Helper to create a comment with optional replies
def create_comment(commentable:, author:, body:, replies: [], vote_score: 0)
  comment = Comment.find_or_create_by!(commentable: commentable, user: author, body: body) do |c|
    c.vote_score = vote_score
  end

  replies.each do |reply_data|
    Comment.find_or_create_by!(
      commentable: commentable,
      user: reply_data[:author],
      body: reply_data[:body],
      parent_comment: comment
    ) do |c|
      c.vote_score = reply_data[:vote_score] || 0
    end
  end

  comment
end

puts "Seeding database..."
