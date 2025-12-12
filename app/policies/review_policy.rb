# frozen_string_literal: true

class ReviewPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    user.present?
  end

  def respond?
    user.present? && record.reviewee_id == user.id && !record.has_response?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # Users can see published reviews or reviews they wrote/received
      scope.where(status: "published")
           .or(scope.where(reviewer_id: user.id))
           .or(scope.where(reviewee_id: user.id))
    end
  end
end
