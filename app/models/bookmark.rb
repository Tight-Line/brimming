# frozen_string_literal: true

class Bookmark < ApplicationRecord
  BOOKMARKABLE_TYPES = %w[Question Answer Comment Article].freeze

  belongs_to :user
  belongs_to :bookmarkable, polymorphic: true

  validates :user_id, uniqueness: { scope: [ :bookmarkable_type, :bookmarkable_id ],
                                    message: "has already bookmarked this item" }

  scope :questions, -> { where(bookmarkable_type: "Question") }
  scope :answers, -> { where(bookmarkable_type: "Answer") }
  scope :comments, -> { where(bookmarkable_type: "Comment") }
  scope :articles, -> { where(bookmarkable_type: "Article") }
  scope :recent, -> { order(created_at: :desc) }
end
