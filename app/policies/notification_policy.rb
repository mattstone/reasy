# frozen_string_literal: true

class NotificationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && record.user_id == user.id
  end

  def mark_read?
    show?
  end

  def mark_all_read?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end
end
