# frozen_string_literal: true

class CoUserInvitationPolicy < ApplicationPolicy
  def new?
    user.present? && user.can_add_co_users?
  end

  def create?
    new?
  end

  def destroy?
    user.present? && record.inviter_id == user.id && record.pending?
  end

  def resend?
    destroy?
  end

  def revoke?
    destroy?
  end

  def accept?
    user.present? && record.active? && record.email.downcase == user.email.downcase
  end

  def confirm?
    accept?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(inviter_id: user.id)
    end
  end
end
