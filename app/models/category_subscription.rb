# frozen_string_literal: true

class CategorySubscription < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :category

  # Validations
  validates :user_id, uniqueness: { scope: :category_id, message: "is already subscribed to this category" }
end
