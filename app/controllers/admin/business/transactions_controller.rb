# frozen_string_literal: true

module Admin
  module Business
    class TransactionsController < Business::BaseController
      def show
        # Primary Metrics
        @total_value = Transaction.sum(:sale_price_cents).to_f / 100 rescue 0
        @total_count = Transaction.count rescue 0
        @avg_value = @total_count.positive? ? @total_value / @total_count : 0
        @active_count = Transaction.where(status: %w[pending active]).count rescue 0

        # Status Distribution
        @transactions_by_status = Transaction.group(:status).count rescue {}

        # Settlement Stats
        @avg_settlement_days = calculate_avg_settlement_days
        @settlement_success_rate = calculate_settlement_success_rate

        # Transaction Trends
        @transaction_value_trend = metrics_service.transaction_value_trend(30)
        @transaction_count_trend = metrics_service.transaction_count_trend(30)

        # Recent Transactions
        @recent_transactions = Transaction.includes(:property, :buyer, :seller)
                                          .order(created_at: :desc)
                                          .limit(10) rescue []
      end

      private

      def calculate_avg_settlement_days
        completed = Transaction.where(status: "completed")
                               .where.not(settlement_date: nil)
        return 0 if completed.empty?

        # Calculate average days from created_at to settlement_date
        total_days = completed.sum do |t|
          (t.settlement_date - t.created_at.to_date).to_i
        end
        (total_days.to_f / completed.count).round(1)
      rescue StandardError
        0
      end

      def calculate_settlement_success_rate
        total_completed = Transaction.where(status: %w[completed canceled]).count
        return 0 if total_completed.zero?

        successful = Transaction.where(status: "completed").count
        ((successful.to_f / total_completed) * 100).round(1)
      rescue StandardError
        0
      end
    end
  end
end
