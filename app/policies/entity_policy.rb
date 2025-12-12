# frozen_string_literal: true

class EntityPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user_owns_entity?
  end

  def create?
    user.present?
  end

  def update?
    user_owns_entity?
  end

  def destroy?
    user_owns_entity? && !record.is_default?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end

  private

  def user_owns_entity?
    user.present? && record.user_id == user.id
  end
end
