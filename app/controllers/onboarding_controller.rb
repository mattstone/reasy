# frozen_string_literal: true

class OnboardingController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    authorize :onboarding, :show?
  end

  def update
    @user = current_user
    authorize :onboarding, :update?

    if @user.update(onboarding_params)
      redirect_to onboarding_path, notice: "Progress saved."
    else
      render :show
    end
  end

  def complete
    @user = current_user
    authorize :onboarding, :complete?

    @user.update(onboarding_completed_at: Time.current)
    redirect_to dashboard_path, notice: "Welcome to Reasy!"
  end

  private

  def onboarding_params
    params.require(:user).permit(:first_name, :last_name, :phone, roles: [])
  end
end
