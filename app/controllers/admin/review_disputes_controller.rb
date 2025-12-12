# frozen_string_literal: true

module Admin
  class ReviewDisputesController < Admin::BaseController
    before_action :set_dispute, only: [:show, :start_review, :uphold, :reject]

    def index
      @disputes = ReviewDispute.order(created_at: :desc)

      case params[:status]
      when "pending"
        @disputes = @disputes.where(status: "pending")
      when "under_review"
        @disputes = @disputes.where(status: "under_review")
      when "resolved"
        @disputes = @disputes.where(status: %w[upheld rejected])
      end

      @pagy, @disputes = pagy(@disputes.includes(:review, :disputed_by), items: 25)

      @pending_count = ReviewDispute.where(status: "pending").count
      @under_review_count = ReviewDispute.where(status: "under_review").count
      @resolved_count = ReviewDispute.where(status: %w[upheld rejected]).count
    end

    def show
    end

    def start_review
      @dispute.update!(status: "under_review", reviewed_by: current_user, reviewed_at: Time.current)
      redirect_to admin_review_dispute_path(@dispute), notice: "Review started."
    end

    def uphold
      @dispute.update!(status: "upheld", resolution_notes: params[:resolution_notes])
      @dispute.review.update!(status: "removed")
      redirect_to admin_review_disputes_path, notice: "Dispute upheld. Review has been removed."
    end

    def reject
      @dispute.update!(status: "rejected", resolution_notes: params[:resolution_notes])
      redirect_to admin_review_disputes_path, notice: "Dispute rejected. Review remains published."
    end

    private

    def set_dispute
      @dispute = ReviewDispute.find(params[:id])
    end
  end
end
