# frozen_string_literal: true

module Admin
  class KYCVerificationsController < Admin::BaseController
    before_action :set_user, only: [:show, :approve, :reject]

    def index
      @users = User.where(kyc_status: %w[submitted under_review])
                   .order(updated_at: :desc)

      case params[:status]
      when "submitted"
        @users = @users.where(kyc_status: "submitted")
      when "under_review"
        @users = @users.where(kyc_status: "under_review")
      end

      @pagy, @users = pagy(@users, items: 25)

      @submitted_count = User.where(kyc_status: "submitted").count
      @under_review_count = User.where(kyc_status: "under_review").count
      @verified_count = User.where(kyc_status: "verified").count
    end

    def show
    end

    def approve
      @user.update!(
        kyc_status: "verified",
        kyc_verified_at: Time.current
      )
      redirect_to admin_kyc_verifications_path, notice: "KYC verification approved for #{@user.name}."
    end

    def reject
      @user.update!(
        kyc_status: "rejected",
        kyc_rejection_reason: params[:rejection_reason]
      )
      redirect_to admin_kyc_verifications_path, notice: "KYC verification rejected for #{@user.name}."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
