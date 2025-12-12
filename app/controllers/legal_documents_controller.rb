# frozen_string_literal: true

class LegalDocumentsController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def terms
    @document = LegalDocument.published.find_by(document_type: :terms_of_service)
  end

  def privacy
    @document = LegalDocument.published.find_by(document_type: :privacy_policy)
  end

  def accept
    authenticate_user!
    @document = LegalDocument.find(params[:document_id])

    current_user.accepted_legal_documents.create!(
      legal_document: @document,
      accepted_at: Time.current,
      ip_address: request.remote_ip
    )

    redirect_back fallback_location: root_path, notice: "Terms accepted."
  end
end
