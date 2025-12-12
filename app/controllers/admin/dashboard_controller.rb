# frozen_string_literal: true

module Admin
  class DashboardController < Admin::BaseController
    def show
      # User stats
      @total_users = User.count
      @new_users_today = User.where("created_at >= ?", Date.current.beginning_of_day).count
      @new_users_this_week = User.where("created_at >= ?", 7.days.ago).count

      # Property stats
      @total_properties = Property.count
      @active_properties = Property.where(status: "active").count
      @pending_properties = Property.where(status: "pending").count

      # Review stats
      @pending_reviews = Review.held.count
      @disputed_reviews = Review.disputed.count

      # KYC stats
      @pending_kyc = User.where(kyc_status: "submitted").count

      # Recent activity
      @recent_users = User.order(created_at: :desc).limit(5)
      @recent_properties = Property.order(created_at: :desc).limit(5)

      # Quick action counts
      @action_items = {
        pending_reviews: @pending_reviews,
        disputed_reviews: @disputed_reviews,
        pending_kyc: @pending_kyc,
        pending_properties: @pending_properties
      }
    end
  end
end
