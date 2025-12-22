# frozen_string_literal: true

module Buyer
  class OffersController < ApplicationController
    layout "dashboard"

    before_action :ensure_buyer
    skip_after_action :verify_policy_scoped, only: [:index]
    before_action :set_offer, only: [:show]

    def index
      @offers = current_user.offers_made.includes(property: [:user, :hero_image_attachment]).order(created_at: :desc)
      @pending_offers = @offers.where(status: %w[pending submitted viewed])
      @active_offers = @offers.where(status: %w[countered])
      @completed_offers = @offers.where(status: %w[accepted rejected withdrawn expired])
    end

    def show
      authorize @offer
      @property = @offer.property
    end

    private

    def set_offer
      @offer = current_user.offers_made.find(params[:id])
    end

    def ensure_buyer
      unless current_user.buyer?
        redirect_to dashboard_path, alert: "This page is only available to buyers"
      end
    end
  end
end
