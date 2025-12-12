# frozen_string_literal: true

module Admin
  class ProviderVerificationsController < Admin::BaseController
    before_action :set_profile, only: [:show, :approve, :reject]

    def index
      @profiles = ServiceProviderProfile.where(verification_status: %w[submitted under_review])
                                        .order(updated_at: :desc)
                                        .includes(:user)

      case params[:status]
      when "submitted"
        @profiles = @profiles.where(verification_status: "submitted")
      when "under_review"
        @profiles = @profiles.where(verification_status: "under_review")
      end

      @pagy, @profiles = pagy(@profiles, items: 25)

      @submitted_count = ServiceProviderProfile.where(verification_status: "submitted").count
      @under_review_count = ServiceProviderProfile.where(verification_status: "under_review").count
      @verified_count = ServiceProviderProfile.where(verification_status: "verified").count
    end

    def show
    end

    def approve
      @profile.update!(
        verification_status: "verified",
        verified_at: Time.current
      )
      redirect_to admin_provider_verifications_path, notice: "Provider #{@profile.business_name} has been verified."
    end

    def reject
      @profile.update!(
        verification_status: "rejected",
        rejection_reason: params[:rejection_reason]
      )
      redirect_to admin_provider_verifications_path, notice: "Provider #{@profile.business_name} has been rejected."
    end

    private

    def set_profile
      @profile = ServiceProviderProfile.find(params[:id])
    end
  end
end
