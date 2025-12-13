# frozen_string_literal: true

module Admin
  module Business
    class DashboardController < Business::BaseController
      def show
        # Hero Metrics
        @mrr = metrics_service.mrr
        @total_transaction_value = metrics_service.total_transaction_value_this_month
        @active_subscriptions = metrics_service.active_subscriptions
        @conversion_rate = metrics_service.trial_to_paid_conversion_rate

        # Trends
        @mrr_change = metrics_service.mrr_change_percent
        @transaction_change = metrics_service.transaction_value_change_percent
        @subscription_change = metrics_service.subscription_change_percent

        # Charts Data
        @revenue_trend = metrics_service.revenue_trend(30)
        @subscription_growth = metrics_service.subscription_growth(30)
        @transactions_by_status = metrics_service.transactions_by_status

        # Recent Activity
        @recent_transactions = Transaction.order(created_at: :desc).limit(5) rescue []
        @recent_subscriptions = User.where.not(subscription_status: nil)
                                    .order(updated_at: :desc)
                                    .limit(5)
      end
    end
  end
end
