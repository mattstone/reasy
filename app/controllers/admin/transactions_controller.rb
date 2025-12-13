# frozen_string_literal: true

module Admin
  class TransactionsController < Admin::BaseController
    before_action :set_transaction, only: [:show]

    def index
      @transactions = Transaction.order(created_at: :desc).includes(:property, :buyer, :seller)

      case params[:status]
      when "active"
        @transactions = @transactions.where(status: %w[pending in_progress])
      when "completed"
        @transactions = @transactions.where(status: "completed")
      when "cancelled"
        @transactions = @transactions.where(status: "cancelled")
      end

      @pagy, @transactions = pagy(@transactions, items: 25)

      # Stats
      @total_transactions = Transaction.count
      @active_count = Transaction.where(status: %w[pending in_progress]).count
      @completed_count = Transaction.where(status: "completed").count
      @disputed_count = 0  # Disputes tracked separately if needed
    end

    def active
      @transactions = Transaction.where(status: %w[pending in_progress]).order(created_at: :desc).includes(:property, :buyer, :seller)
      @pagy, @transactions = pagy(@transactions, items: 25)
      render :index
    end

    def completed
      @transactions = Transaction.where(status: "completed").order(created_at: :desc).includes(:property, :buyer, :seller)
      @pagy, @transactions = pagy(@transactions, items: 25)
      render :index
    end

    def disputes
      # Disputes feature not yet implemented - show empty list
      @transactions = Transaction.none
      @pagy, @transactions = pagy(@transactions, items: 25)
      render :index
    end

    def show
      @offer = @transaction.offer
      @timeline = @transaction.transaction_events.order(occurred_at: :desc)
    end

    private

    def set_transaction
      @transaction = Transaction.find(params[:id])
    end
  end
end
