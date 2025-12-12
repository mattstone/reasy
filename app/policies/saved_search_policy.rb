# frozen_string_literal: true

class SavedSearchPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user_owns_search?
  end

  def create?
    user.present?
  end

  def update?
    user_owns_search?
  end

  def destroy?
    user_owns_search?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end

  private

  def user_owns_search?
    user.present? && record.user_id == user.id
  end
end
