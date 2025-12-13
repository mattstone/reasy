# frozen_string_literal: true

class KYCVerificationsController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!

  def show
    authorize current_user, :show?, policy_class: KYCVerificationPolicy
  end

  def create
    authorize current_user, :create?, policy_class: KYCVerificationPolicy

    # This would typically integrate with a KYC service
    # For now, we'll just update the status to submitted
    current_user.update!(kyc_status: "submitted")

    redirect_to kyc_verification_path, notice: "Your verification documents have been submitted for review."
  end

  def update
    authorize current_user, :update?, policy_class: KYCVerificationPolicy

    # Handle file uploads here in production
    # For now, just mark as submitted
    current_user.update!(kyc_status: "submitted")

    redirect_to kyc_verification_path, notice: "Your verification has been updated and resubmitted."
  end

  def submit
    authorize current_user, :submit?, policy_class: KYCVerificationPolicy

    if params[:id_document].present? && params[:selfie].present?
      # In production, these would be uploaded to secure storage
      # and sent to a KYC verification service (e.g., Onfido, Jumio)

      current_user.update!(kyc_status: "submitted")

      redirect_to kyc_verification_path, notice: "Your verification documents have been submitted. We'll notify you once review is complete."
    else
      redirect_to kyc_verification_path, alert: "Please provide both ID document and selfie."
    end
  end
end
