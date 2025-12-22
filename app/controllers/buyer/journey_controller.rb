# frozen_string_literal: true

module Buyer
  class JourneyController < ApplicationController
    layout "dashboard"

    before_action :ensure_buyer
    skip_after_action :verify_authorized, only: [:show]

    def show
      @user = current_user
      @buyer_checklist = JourneyChecklist.find_by(journey_type: "buyer")
      @checklist_items = @buyer_checklist&.checklist_items&.order(:position) || []
      @progress = current_user.checklist_progress_for("buyer")
      @achievements = current_user.user_achievements.includes(:journey_checklist).order(awarded_at: :desc)
    end

    private

    def ensure_buyer
      unless current_user.buyer?
        redirect_to dashboard_path, alert: "This page is only available to buyers"
      end
    end
  end
end
