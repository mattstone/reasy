# frozen_string_literal: true

module Admin
  module Business
    class RevenueController < Business::BaseController
      def show
        # Primary Metrics
        @mrr = metrics_service.mrr
        @arr = metrics_service.arr
        @arpu = metrics_service.arpu
        @churn_rate = metrics_service.churn_rate
        @ltv = metrics_service.lifetime_value

        # Revenue Breakdown
        @revenue_by_plan = metrics_service.revenue_by_plan
        @mrr_growth = metrics_service.mrr_growth_trend(90)

        # Churn Analysis
        @churned_users = User.where(subscription_status: "canceled")
                             .where("updated_at >= ?", 30.days.ago)
                             .count
        @churn_trend = metrics_service.churn_trend(90)

        # Cohort Data (simplified)
        @cohort_retention = metrics_service.cohort_retention_data
      end
    end
  end
end
