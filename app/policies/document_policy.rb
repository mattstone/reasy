# frozen_string_literal: true

class DocumentPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && can_view?
  end

  def create?
    user.present?
  end

  def destroy?
    user.present? && record.user_id == user.id
  end

  private

  def can_view?
    record.user_id == user.id ||
      record.public? ||
      record.shared?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.visible_to(user)
    end
  end
end
