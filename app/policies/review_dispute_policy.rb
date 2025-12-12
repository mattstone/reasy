# frozen_string_literal: true

class ReviewDisputePolicy < ApplicationPolicy
  def new?
    user.present? && can_dispute_review?
  end

  def create?
    new?
  end

  private

  def can_dispute_review?
    review = record.review
    return false unless review

    # Only the reviewee can dispute a review
    review.reviewee_id == user.id &&
      !review.has_active_dispute? &&
      review.published?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(disputed_by_id: user.id)
    end
  end
end
