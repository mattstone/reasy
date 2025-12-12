# frozen_string_literal: true

class OfferPolicy < ApplicationPolicy
  def new?
    create?
  end

  def create?
    return false unless user.present?
    return false unless user.buyer_profile.present?
    return false if record.property&.user_id == user.id # Can't offer on own property

    true
  end

  def show?
    return false unless user.present?

    # Buyer can see their own offers
    return true if record.buyer_id == user.id

    # Seller can see offers on their properties
    return true if record.property&.user_id == user.id

    false
  end

  def withdraw?
    return false unless user.present?
    return false unless record.buyer_id == user.id
    return false if record.finalized?

    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # User can see offers they made or offers on properties they own
      scope.left_joins(:property)
           .where("offers.buyer_id = ? OR properties.user_id = ?", user.id, user.id)
    end
  end
end
