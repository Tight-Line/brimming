# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  # Anyone can view tags
  def index?
    true
  end

  def show?
    true
  end

  def search?
    true
  end

  # Only space moderators or admins can create/update/delete tags
  def create?
    user&.admin? || space_moderator?
  end

  def update?
    user&.admin? || space_moderator?
  end

  def destroy?
    user&.admin? || space_moderator?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  private

  def space_moderator?
    return false unless user && record.space

    record.space.moderator?(user)
  end
end
