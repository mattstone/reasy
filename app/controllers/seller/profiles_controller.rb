# frozen_string_literal: true

module Seller
  class ProfilesController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :set_seller_profile

    def show
      authorize @seller_profile
    end

    def edit
      authorize @seller_profile
    end

    def update
      authorize @seller_profile

      if @seller_profile.update(seller_profile_params)
        redirect_to seller_profile_path, notice: "Your seller profile has been updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_seller_profile
      @seller_profile = current_user.ensure_seller_profile
    end

    def seller_profile_params
      params.require(:seller_profile).permit(
        :preferred_settlement_period,
        :specific_settlement_date,
        :preferred_contact_method,
        :allow_direct_contact,
        :allow_scheduled_viewings,
        :accept_cash_buyers,
        :accept_pre_approved_buyers,
        :accept_finance_buyers,
        :minimum_deposit_percentage,
        :additional_requirements,
        :default_entity_id,
        viewing_availability: {}
      )
    end
  end
end
