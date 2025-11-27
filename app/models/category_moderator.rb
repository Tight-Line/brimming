# frozen_string_literal: true

class CategoryModerator < ApplicationRecord
  # Associations
  belongs_to :category
  belongs_to :user

  # Validations
  validates :user_id, uniqueness: { scope: :category_id, message: "is already a moderator of this category" }
end
