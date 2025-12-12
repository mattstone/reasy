# frozen_string_literal: true

class SellerProfilePolicy < ApplicationPolicy
  def show?
    user_owns_profile?
  end

  def edit?
    user_owns_profile?
  end

  def update?
    user_owns_profile?
  end

  private

  def user_owns_profile?
    user.present? && record.user_id == user.id
  end
end
