# frozen_string_literal: true

module Admin
  module Business
    class UsersController < Business::BaseController
      def show
        # Primary Metrics
        @total_users = User.count
        @new_users_this_week = User.where("created_at >= ?", 1.week.ago).count
        @new_users_this_month = User.where("created_at >= ?", 1.month.ago).count
        @active_users_today = User.where("last_sign_in_at >= ?", 1.day.ago).count rescue 0

        # User Distribution
        @users_by_role = {
          buyers: User.where("'buyer' = ANY(roles)").count,
          sellers: User.where("'seller' = ANY(roles)").count,
          service_providers: User.where("'service_provider' = ANY(roles)").count,
          admins: User.where("'admin' = ANY(roles)").count
        }

        # KYC Stats
        @kyc_stats = User.group(:kyc_status).count
        @kyc_completion_rate = calculate_kyc_completion_rate

        # User Funnel
        @funnel_data = calculate_user_funnel

        # Growth Charts
        @daily_signups = metrics_service.daily_signups(30)
        @weekly_active_users = metrics_service.weekly_active_users(12)
      end

      private

      def calculate_kyc_completion_rate
        total = User.count
        verified = User.where(kyc_status: "verified").count
        return 0 if total.zero?
        ((verified.to_f / total) * 100).round(1)
      end

      def calculate_user_funnel
        total_registered = User.count
        completed_onboarding = User.where.not(onboarding_completed_at: nil).count
        kyc_submitted = User.where(kyc_status: %w[submitted verified]).count
        subscribed = User.where(subscription_status: %w[active trialing]).count

        [
          { label: "Registered", value: total_registered, color: "#3b82f6" },
          { label: "Completed Onboarding", value: completed_onboarding, color: "#22c55e" },
          { label: "KYC Submitted", value: kyc_submitted, color: "#f59e0b" },
          { label: "Subscribed", value: subscribed, color: "#8b5cf6" }
        ]
      end
    end
  end
end
