# frozen_string_literal: true

class SpaceSubscription < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :space

  # Validations
  validates :user_id, uniqueness: { scope: :space_id, message: "is already subscribed to this space" }
end
