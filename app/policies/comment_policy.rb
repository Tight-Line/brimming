# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  # Anyone can view comments (shown on question page)
  def show?
    true
  end

  # Logged-in users can create comments
  def create?
    user.present?
  end

  # Only the owner can edit/update their comment
  def update?
    user.present? && record.owned_by?(user)
  end

  # Only the owner can soft-delete their comment
  def destroy?
    user.present? && record.owned_by?(user)
  end

  # Only moderators/admins can hard-delete
  def hard_delete?
    user.present? && user.can_moderate?(record.space)
  end

  # Logged-in users can vote on comments
  def vote?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.not_deleted
    end
  end
end
