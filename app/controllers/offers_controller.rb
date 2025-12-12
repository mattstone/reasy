# frozen_string_literal: true

class OffersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property, only: %i[new create]
  before_action :set_offer, only: %i[show withdraw]
  before_action :ensure_buyer_profile, only: %i[new create]

  def new
    @offer = @property.offers.build(
      buyer: current_user,
      finance_type: current_user.buyer_profile&.finance_status == "cash" ? "cash" : "pre_approved",
      settlement_days: 42
    )
    authorize @offer

    @entities = current_user.entities
  end

  def create
    @offer = @property.offers.build(offer_params)
    @offer.buyer = current_user
    @offer.status = "submitted"
    @offer.submitted_at = Time.current
    authorize @offer

    @entities = current_user.entities

    if @offer.save
      respond_to do |format|
        format.html { redirect_to offer_path(@offer), notice: "Your offer has been submitted!" }
        format.turbo_stream { redirect_to offer_path(@offer), notice: "Your offer has been submitted!" }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @offer
    @property = @offer.property
  end

  def withdraw
    authorize @offer, :withdraw?

    if @offer.withdraw!
      redirect_to offer_path(@offer), notice: "Your offer has been withdrawn."
    else
      redirect_to offer_path(@offer), alert: "Unable to withdraw this offer."
    end
  end

  private

  def set_property
    @property = Property.active.find(params[:property_id])
  end

  def set_offer
    @offer = Offer.find(params[:id])
  end

  def ensure_buyer_profile
    return if current_user.buyer_profile.present?

    redirect_to edit_buyer_profile_path, alert: "Please complete your buyer profile before making an offer."
  end

  def offer_params
    params.require(:offer).permit(
      :amount,
      :deposit,
      :finance_type,
      :settlement_days,
      :subject_to_finance,
      :subject_to_building_inspection,
      :subject_to_pest_inspection,
      :subject_to_valuation,
      :subject_to_sale_of_property,
      :other_conditions,
      :buyer_entity_id,
      :message
    )
  end
end
