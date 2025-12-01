# frozen_string_literal: true

class ArticlePolicy < ApplicationPolicy
  # Anyone can view articles index
  def index?
    true
  end

  # Anyone can view published articles
  def show?
    true
  end

  # Publishers in any space, moderators, or admins can create articles
  # Note: On creation, the article is orphaned (not yet assigned to spaces)
  def create?
    return false unless user.present?

    user.admin? || user.publisher? || user.moderator?
  end

  # Owner, publishers/moderators of article's spaces, or admins can update
  def update?
    return false unless user.present?

    user.admin? || record.owned_by?(user) || can_publish_in_any_space?
  end

  # Owner, publishers/moderators of article's spaces, or admins can soft-delete
  def destroy?
    return false unless user.present?

    user.admin? || record.owned_by?(user) || can_publish_in_any_space?
  end

  # Only moderators of article's spaces or admins can hard-delete
  def hard_delete?
    return false unless user.present?

    user.admin? || can_moderate_any_space?
  end

  # Logged-in users can vote
  def vote?
    user.present?
  end

  # Owner, publishers/moderators of article's spaces, or admins can manage space assignments
  def manage_spaces?
    return false unless user.present?

    user.admin? || record.owned_by?(user) || can_publish_in_any_space?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.active
    end
  end

  private

  def can_publish_in_any_space?
    record.spaces.any? { |space| user.can_publish?(space) }
  end

  def can_moderate_any_space?
    record.spaces.any? { |space| user.can_moderate?(space) }
  end
end
