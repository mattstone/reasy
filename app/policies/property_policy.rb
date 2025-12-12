# frozen_string_literal: true

class PropertyPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
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
