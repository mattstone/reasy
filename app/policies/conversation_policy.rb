# frozen_string_literal: true

class ConversationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && record.participant?(user)
  end

  def create?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:conversation_participants)
           .where(conversation_participants: { user_id: user.id, archived: false })
    end
  end
end
