# frozen_string_literal: true

module Seller
  class JourneyController < ApplicationController
    layout "dashboard"

    before_action :ensure_seller
    skip_after_action :verify_authorized, only: [:show]

    def show
      @user = current_user
      @seller_checklist = JourneyChecklist.find_by(journey_type: "seller")
      @checklist_items = @seller_checklist&.checklist_items&.order(:position) || []
      @progress = current_user.checklist_progress_for("seller")
      @achievements = current_user.user_achievements.includes(:journey_checklist).order(awarded_at: :desc)
    end

    private

    def ensure_seller
      unless current_user.seller?
        redirect_to dashboard_path, alert: "This page is only available to sellers"
      end
    end
  end
end
