# frozen_string_literal: true

class SpacePolicy < ApplicationPolicy
  # Anyone can view spaces
  def index?
    true
  end

  def show?
    true
  end

  # Only admins can manage spaces
  def create?
    user&.admin?
  end

  def update?
    user&.admin? || record.moderator?(user)
  end

  def destroy?
    user&.admin?
  end

  # Moderator management - admins or space moderators
  def manage_moderators?
    user&.admin? || record.moderator?(user)
  end

  # Publisher management - admins only
  def manage_publishers?
    user&.admin?
  end

  # Any logged-in user can subscribe to a space
  def subscribe?
    user.present?
  end

  # Any logged-in user can unsubscribe from a space
  def unsubscribe?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
