# frozen_string_literal: true

class OnboardingPolicy < Struct.new(:user, :onboarding)
  def show?
    user.present?
  end

  def update?
    user.present?
  end

  def complete?
    user.present?
  end
end
