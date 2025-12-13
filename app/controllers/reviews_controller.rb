# frozen_string_literal: true

class ReviewsController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!
  before_action :set_review, only: [:show, :respond]

  def index
    @reviews = policy_scope(Review).recent
    @pagy, @reviews = pagy(@reviews, items: 20)

    # Filter by type if specified
    case params[:type]
    when "given"
      @reviews = @reviews.where(reviewer_id: current_user.id)
    when "received"
      @reviews = @reviews.where(reviewee_id: current_user.id)
    end

    @reviews_given_count = Review.where(reviewer_id: current_user.id).count
    @reviews_received_count = Review.where(reviewee_id: current_user.id).count
    @average_rating = Review.where(reviewee_id: current_user.id).published.average(:overall_rating)&.round(1) || 0
  end

  def show
    authorize @review
  end

  def new
    @reviewee = User.find(params[:reviewee_id])
    @review = Review.new(reviewee: @reviewee, reviewee_role: determine_reviewee_role(@reviewee))
    authorize @review
  end

  def create
    @review = Review.new(review_params)
    @review.reviewer = current_user
    authorize @review

    if @review.save
      if @review.held?
        redirect_to @review, notice: "Your review has been submitted and will be published after a 48-hour review period."
      else
        redirect_to @review, notice: "Your review has been published."
      end
    else
      @reviewee = @review.reviewee
      render :new, status: :unprocessable_entity
    end
  end

  def respond
    authorize @review

    if @review.add_response!(params[:public_response])
      redirect_to @review, notice: "Your response has been added."
    else
      redirect_to @review, alert: "Failed to add response."
    end
  end

  private

  def set_review
    @review = Review.find(params[:id])
  end

  def review_params
    params.require(:review).permit(
      :reviewee_id,
      :reviewee_role,
      :overall_rating,
      :title,
      :body,
      category_ratings: {}
    )
  end

  def determine_reviewee_role(user)
    if user.service_provider?
      "service_provider"
    elsif user.seller?
      "seller"
    else
      "buyer"
    end
  end
end
