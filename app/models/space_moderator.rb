# frozen_string_literal: true

class SpaceModerator < ApplicationRecord
  # Associations
  belongs_to :space
  belongs_to :user

  # Validations
  validates :user_id, uniqueness: { scope: :space_id, message: "is already a moderator of this space" }
end
