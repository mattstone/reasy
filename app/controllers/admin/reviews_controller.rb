# frozen_string_literal: true

module Admin
  class ReviewsController < Admin::BaseController
    before_action :set_review, only: [:show, :publish, :hold, :remove]

    def index
      @reviews = Review.recent.includes(:reviewer, :reviewee)

      case params[:filter]
      when "pending"
        @reviews = @reviews.pending
      when "held"
        @reviews = @reviews.held
      when "disputed"
        @reviews = @reviews.disputed
      end

      @pagy, @reviews = pagy(@reviews, items: 25)

      @pending_count = Review.pending.count
      @held_count = Review.held.count
      @disputed_count = Review.disputed.count
    end

    def pending
      @reviews = Review.pending.recent.includes(:reviewer, :reviewee)
      @pagy, @reviews = pagy(@reviews, items: 25)
      render :index
    end

    def held
      @reviews = Review.held.recent.includes(:reviewer, :reviewee)
      @pagy, @reviews = pagy(@reviews, items: 25)
      render :index
    end

    def show
    end

    def publish
      if @review.publish!
        redirect_to admin_review_path(@review), notice: "Review has been published."
      else
        redirect_to admin_review_path(@review), alert: "Failed to publish review."
      end
    end

    def hold
      if @review.hold!(reason: params[:reason])
        redirect_to admin_review_path(@review), notice: "Review has been put on hold."
      else
        redirect_to admin_review_path(@review), alert: "Failed to hold review."
      end
    end

    def remove
      if @review.remove!(admin_notes: params[:admin_notes])
        redirect_to admin_reviews_path, notice: "Review has been removed."
      else
        redirect_to admin_review_path(@review), alert: "Failed to remove review."
      end
    end

    private

    def set_review
      @review = Review.find(params[:id])
    end
  end
end
