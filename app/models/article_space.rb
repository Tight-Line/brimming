# frozen_string_literal: true

class ArticleSpace < ApplicationRecord
  # Associations
  belongs_to :article
  belongs_to :space

  # Validations
  validates :article_id, uniqueness: {
    scope: :space_id,
    message: "is already associated with this space"
  }
end
