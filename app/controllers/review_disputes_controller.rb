# frozen_string_literal: true

class ReviewDisputesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_review

  def new
    @dispute = @review.review_disputes.build(disputed_by: current_user)
    authorize @dispute
  end

  def create
    @dispute = @review.review_disputes.build(dispute_params)
    @dispute.disputed_by = current_user
    authorize @dispute

    if @dispute.save
      redirect_to review_path(@review), notice: "Your dispute has been submitted and will be reviewed by our moderation team."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_review
    @review = Review.find(params[:review_id])
  end

  def dispute_params
    params.require(:review_dispute).permit(:reason, :explanation)
  end
end
