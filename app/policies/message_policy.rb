# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  def create?
    user.present? && record.conversation.participant?(user)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(conversation: :conversation_participants)
           .where(conversation_participants: { user_id: user.id })
    end
  end
end
