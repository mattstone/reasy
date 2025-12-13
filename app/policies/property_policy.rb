# frozen_string_literal: true

class PropertyPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  # Seller actions
  def new?
    create?
  end

  def create?
    user.present? && user.seller?
  end

  def update?
    user.present? && record.user_id == user.id
  end

  def edit?
    update?
  end

  def destroy?
    user.present? && record.user_id == user.id && record.draft?
  end

  def publish?
    update? && record.can_publish?
  end

  def unpublish?
    update? && record.active?
  end

  def archive?
    update?
  end

  def enquire?
    user.present? && user.buyer_profile.present?
  end

  def love?
    user.present?
  end

  def unlove?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.active
    end
  end
end
