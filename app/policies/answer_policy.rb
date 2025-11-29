# frozen_string_literal: true

class AnswerPolicy < ApplicationPolicy
  # Anyone can view answers (shown on question page)
  def show?
    true
  end

  # Logged-in users can create answers
  def create?
    user.present?
  end

  # Only the owner can edit/update their answer
  def update?
    user.present? && record.owned_by?(user)
  end

  # Only the owner can soft-delete their answer
  def destroy?
    user.present? && record.owned_by?(user)
  end

  # Only moderators/admins can hard-delete
  def hard_delete?
    user.present? && user.can_moderate?(record.space)
  end

  # Logged-in users can vote
  def vote?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.not_deleted
    end
  end
end
