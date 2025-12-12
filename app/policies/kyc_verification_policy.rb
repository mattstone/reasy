# frozen_string_literal: true

class KYCVerificationPolicy < ApplicationPolicy
  def show?
    user.present?
  end

  def create?
    user.present? && user.kyc_pending?
  end

  def update?
    user.present? && user.kyc_status.in?(%w[pending rejected])
  end

  def submit?
    update?
  end
end
