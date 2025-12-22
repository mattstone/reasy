# frozen_string_literal: true

class PropertyOffersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property_from_seo_params
  before_action :ensure_buyer_profile

  def new
    @offer = @property.offers.build
    authorize @offer
  end

  def create
    @offer = @property.offers.build(offer_params)
    @offer.buyer = current_user
    @offer.buyer_entity = current_user.default_entity

    authorize @offer

    if @offer.save
      @offer.submit!
      redirect_to seo_properties_path(@property.to_seo_params), notice: "Your offer has been submitted successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_property_from_seo_params
    @property = Property.active
                        .where("LOWER(state) = ?", params[:state]&.downcase)
                        .find_by!(slug: params[:slug])
  end

  def ensure_buyer_profile
    return if current_user.buyer_profile.present?

    redirect_to onboarding_path, alert: "Please complete your buyer profile first."
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
      :message
    )
  end
end
