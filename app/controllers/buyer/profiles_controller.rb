# frozen_string_literal: true

module Buyer
  class ProfilesController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :set_buyer_profile

    def show
      authorize @buyer_profile
    end

    def edit
      authorize @buyer_profile
    end

    def update
      authorize @buyer_profile

      if @buyer_profile.update(buyer_profile_params)
        redirect_to buyer_profile_path, notice: "Your buyer profile has been updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_buyer_profile
      @buyer_profile = current_user.ensure_buyer_profile
    end

    def buyer_profile_params
      params.require(:buyer_profile).permit(
        :budget_min,
        :budget_max,
        :finance_status,
        :pre_approval_amount,
        :pre_approval_expires_at,
        :pre_approval_lender,
        :buying_timeline,
        :min_bedrooms,
        :max_bedrooms,
        :min_bathrooms,
        :min_parking,
        :max_commute_time,
        :first_home_buyer,
        :additional_notes,
        preferred_property_types: [],
        must_have_features: [],
        nice_to_have_features: [],
        preferred_suburbs: [],
        location_preferences: {},
        score_weights: {}
      )
    end
  end
end
