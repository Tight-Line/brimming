# frozen_string_literal: true

class SpacePublisher < ApplicationRecord
  belongs_to :user
  belongs_to :space

  validates :user_id, uniqueness: { scope: :space_id, message: "is already a publisher for this space" }
end
