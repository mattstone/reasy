# frozen_string_literal: true

module Seller
  class OffersController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    skip_after_action :verify_policy_scoped, only: [:index]
    before_action :set_property
    before_action :set_offer, only: %i[show accept reject counter]

    def index
      authorize @property, :update?

      @offers = @property.offers.recent.includes(:buyer, :buyer_entity)
      @active_offers = @offers.active
      @responded_offers = @offers.responded
    end

    def show
      authorize @offer

      @offer.mark_viewed! if @offer.submitted? && @offer.buyer != current_user
    end

    def accept
      authorize @offer

      if @offer.accept!(seller_response: params[:seller_response])
        redirect_to seller_property_offer_path(@property, @offer), notice: "Offer accepted! A transaction has been created."
      else
        redirect_to seller_property_offer_path(@property, @offer), alert: "Could not accept this offer."
      end
    end

    def reject
      authorize @offer

      if @offer.reject!(seller_response: params[:seller_response])
        redirect_to seller_property_offer_path(@property, @offer), notice: "Offer rejected."
      else
        redirect_to seller_property_offer_path(@property, @offer), alert: "Could not reject this offer."
      end
    end

    def counter
      authorize @offer

      counter_amount = (params[:counter_amount].to_f * 100).to_i

      if counter_amount <= 0
        redirect_to seller_property_offer_path(@property, @offer), alert: "Please enter a valid counter amount."
        return
      end

      options = {
        counter_amount_cents: counter_amount,
        settlement_days: params[:settlement_days].presence&.to_i,
        subject_to_finance: params[:subject_to_finance] == "1",
        subject_to_building_inspection: params[:subject_to_building_inspection] == "1",
        subject_to_pest_inspection: params[:subject_to_pest_inspection] == "1"
      }.compact

      if @offer.counter!(**options)
        redirect_to seller_property_offers_path(@property), notice: "Counter-offer sent to buyer."
      else
        redirect_to seller_property_offer_path(@property, @offer), alert: "Could not create counter-offer."
      end
    end

    private

    def set_property
      @property = current_user.properties.find(params[:property_id])
    end

    def set_offer
      @offer = @property.offers.find(params[:id])
    end
  end
end
