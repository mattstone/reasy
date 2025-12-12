# frozen_string_literal: true

module Provider
  class ProfilesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_service_provider_profile

    def show
      authorize @service_provider_profile
    end

    def edit
      authorize @service_provider_profile
    end

    def update
      authorize @service_provider_profile

      if @service_provider_profile.update(service_provider_profile_params)
        redirect_to provider_profile_path, notice: "Your service provider profile has been updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_service_provider_profile
      @service_provider_profile = current_user.service_provider_profile

      unless @service_provider_profile
        redirect_to dashboard_path, alert: "You need to set up a service provider profile first."
      end
    end

    def service_provider_profile_params
      params.require(:service_provider_profile).permit(
        :business_name,
        :service_type,
        :description,
        :abn,
        :license_number,
        :years_experience,
        :response_time_commitment,
        :accepting_new_clients,
        :website_url,
        :phone_number,
        service_areas: [],
        differentiators: [],
        pricing: {},
        availability: {},
        credentials: [:name, :issuer, :verified]
      )
    end
  end
end
