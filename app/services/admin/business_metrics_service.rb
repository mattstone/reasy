# frozen_string_literal: true

module Admin
  class BusinessMetricsService
    # Monthly Recurring Revenue
    def mrr
      # Calculate from active subscriptions
      active_subs = User.where(subscription_status: %w[active trialing])
      # Assuming monthly plans - adjust based on actual pricing
      active_subs.count * 49 # Default price per month in dollars
    rescue StandardError
      0
    end

    # Annual Recurring Revenue
    def arr
      mrr * 12
    end

    # Average Revenue Per User
    def arpu
      paying_users = User.where(subscription_status: "active").count
      return 0 if paying_users.zero?
      (mrr.to_f / paying_users).round(2)
    rescue StandardError
      0
    end

    # Churn Rate (monthly)
    def churn_rate
      start_count = User.where("created_at < ?", 30.days.ago)
                        .where(subscription_status: %w[active trialing])
                        .count
      return 0 if start_count.zero?

      churned = User.where(subscription_status: "canceled")
                    .where("updated_at >= ?", 30.days.ago)
                    .count
      ((churned.to_f / start_count) * 100).round(2)
    rescue StandardError
      0
    end

    # Customer Lifetime Value
    def lifetime_value
      return 0 if churn_rate.zero?
      (arpu / (churn_rate / 100)).round(2)
    rescue StandardError
      0
    end

    # Trial to Paid Conversion Rate
    def trial_to_paid_conversion_rate
      trialed = User.where(subscription_status: %w[active canceled])
                    .where.not(trial_ends_at: nil)
                    .count
      return 0 if trialed.zero?

      converted = User.where(subscription_status: "active")
                      .where.not(trial_ends_at: nil)
                      .count
      ((converted.to_f / trialed) * 100).round(1)
    rescue StandardError
      0
    end

    # Active Subscriptions
    def active_subscriptions
      User.where(subscription_status: %w[active trialing]).count
    rescue StandardError
      0
    end

    # Total Transaction Value This Month
    def total_transaction_value_this_month
      Transaction.where("created_at >= ?", Date.current.beginning_of_month)
                 .sum(:sale_price_cents).to_f / 100
    rescue StandardError
      0
    end

    # MRR Change Percent (month over month)
    def mrr_change_percent
      current_month_subs = User.where(subscription_status: %w[active trialing]).count
      last_month_subs = User.where(subscription_status: %w[active trialing])
                            .where("created_at < ?", 30.days.ago)
                            .count

      return 0 if last_month_subs.zero?
      (((current_month_subs - last_month_subs).to_f / last_month_subs) * 100).round(1)
    rescue StandardError
      0
    end

    # Transaction Value Change Percent
    def transaction_value_change_percent
      this_month = Transaction.where("created_at >= ?", 30.days.ago).sum(:sale_price_cents)
      last_month = Transaction.where("created_at >= ? AND created_at < ?", 60.days.ago, 30.days.ago)
                              .sum(:sale_price_cents)

      return 0 if last_month.zero?
      (((this_month - last_month).to_f / last_month) * 100).round(1)
    rescue StandardError
      0
    end

    # Subscription Change Percent
    def subscription_change_percent
      new_subs = User.where(subscription_status: %w[active trialing])
                     .where("created_at >= ?", 7.days.ago)
                     .count

      previous_week = User.where(subscription_status: %w[active trialing])
                          .where("created_at >= ? AND created_at < ?", 14.days.ago, 7.days.ago)
                          .count

      return 0 if previous_week.zero?
      (((new_subs - previous_week).to_f / previous_week) * 100).round(1)
    rescue StandardError
      0
    end

    # Revenue Trend (last n days)
    def revenue_trend(days)
      start_date = days.days.ago.to_date

      (start_date..Date.current).map do |date|
        subs_count = User.where(subscription_status: %w[active trialing])
                         .where("created_at <= ?", date.end_of_day)
                         .count
        {
          date: date.to_s,
          value: subs_count * 49 # Monthly price
        }
      end
    rescue StandardError
      []
    end

    # Subscription Growth Trend
    def subscription_growth(days)
      User.where("created_at >= ?", days.days.ago)
          .where(subscription_status: %w[active trialing])
          .group_by_day(:created_at)
          .count
          .map { |date, count| { date: date.to_s, value: count } }
    rescue StandardError
      []
    end

    # Transactions by Status
    def transactions_by_status
      Transaction.group(:status).count.map do |status, count|
        { label: status&.humanize || "Unknown", value: count }
      end
    rescue StandardError
      []
    end

    # Revenue by Plan Type
    def revenue_by_plan
      # Simplified - assuming single plan type
      [
        { label: "Monthly", value: active_subscriptions * 49, color: "#22c55e" },
        { label: "Annual", value: 0, color: "#3b82f6" }
      ]
    rescue StandardError
      []
    end

    # MRR Growth Trend
    def mrr_growth_trend(days)
      revenue_trend(days)
    end

    # Churn Trend
    def churn_trend(days)
      User.where(subscription_status: "canceled")
          .where("updated_at >= ?", days.days.ago)
          .group_by_day(:updated_at)
          .count
          .map { |date, count| { date: date.to_s, value: count } }
    rescue StandardError
      []
    end

    # Cohort Retention Data (simplified)
    def cohort_retention_data
      # Return placeholder data - real implementation would be more complex
      []
    end

    # Daily Signups
    def daily_signups(days)
      User.where("created_at >= ?", days.days.ago)
          .group_by_day(:created_at)
          .count
          .map { |date, count| { date: date.to_s, value: count } }
    rescue StandardError
      []
    end

    # Weekly Active Users
    def weekly_active_users(weeks)
      (0...weeks).map do |i|
        week_start = (i + 1).weeks.ago.beginning_of_week
        week_end = week_start.end_of_week
        count = User.where("last_sign_in_at >= ? AND last_sign_in_at <= ?", week_start, week_end).count rescue 0
        {
          date: week_start.strftime("%b %d"),
          value: count
        }
      end.reverse
    rescue StandardError
      []
    end

    # Transaction Value Trend
    def transaction_value_trend(days)
      Transaction.where("created_at >= ?", days.days.ago)
                 .group_by_day(:created_at)
                 .sum(:sale_price_cents)
                 .map { |date, cents| { date: date.to_s, value: cents / 100.0 } }
    rescue StandardError
      []
    end

    # Transaction Count Trend
    def transaction_count_trend(days)
      Transaction.where("created_at >= ?", days.days.ago)
                 .group_by_day(:created_at)
                 .count
                 .map { |date, count| { date: date.to_s, value: count } }
    rescue StandardError
      []
    end
  end
end
