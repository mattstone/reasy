# frozen_string_literal: true

class CoUserPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && (record.primary_user_id == user.id || record.co_user_id == user.id)
  end

  def destroy?
    user.present? && record.primary_user_id == user.id
  end

  def invitations?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # Show relationships where user is primary or co-user
      scope.where(primary_user_id: user.id)
           .or(scope.where(co_user_id: user.id))
    end
  end
end
