# frozen_string_literal: true

module Admin
  class AnalyticsController < Admin::BaseController
    def show
      @total_users = User.count
      @new_users_this_week = User.where("created_at >= ?", 1.week.ago).count
      @new_users_this_month = User.where("created_at >= ?", 1.month.ago).count

      @total_properties = Property.count
      @active_properties = Property.where(status: "active").count
      @sold_properties = Property.where(status: "sold").count

      @total_transactions = Transaction.count rescue 0
      @active_transactions = Transaction.where(status: %w[pending active]).count rescue 0
    end

    def users
      @users_by_role = {
        buyers: User.where("'buyer' = ANY(roles)").count,
        sellers: User.where("'seller' = ANY(roles)").count,
        providers: User.where("'service_provider' = ANY(roles)").count
      }

      @users_by_kyc = User.group(:kyc_status).count
      @users_by_subscription = User.group(:subscription_status).count

      @recent_signups = User.where("created_at >= ?", 30.days.ago)
                            .group_by_day(:created_at)
                            .count rescue {}
    end

    def properties
      @properties_by_status = Property.group(:status).count
      @properties_by_type = Property.group(:property_type).count
      @properties_by_state = Property.group(:state).count

      @recent_listings = Property.where("created_at >= ?", 30.days.ago)
                                 .group_by_day(:created_at)
                                 .count rescue {}
    end

    def transactions
      @transactions_by_status = Transaction.group(:status).count rescue {}
      @total_value = Transaction.sum(:sale_price_cents).to_f / 100 rescue 0

      @recent_transactions = Transaction.where("created_at >= ?", 30.days.ago)
                                        .group_by_day(:created_at)
                                        .count rescue {}
    end
  end
end
