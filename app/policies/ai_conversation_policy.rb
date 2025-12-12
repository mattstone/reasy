# frozen_string_literal: true

class AIConversationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user_owns_conversation?
  end

  def create?
    user.present?
  end

  def update?
    user_owns_conversation?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end

  private

  def user_owns_conversation?
    user.present? && record.user_id == user.id
  end
end
