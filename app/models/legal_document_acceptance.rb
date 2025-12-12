# frozen_string_literal: true

class LegalDocumentAcceptance < ApplicationRecord
  include Auditable

  belongs_to :user
  belongs_to :legal_document

  validates :user_id, uniqueness: { scope: :legal_document_id, message: "has already accepted this document" }
  validates :accepted_at, presence: true

  # Scopes
  scope :recent, -> { order(accepted_at: :desc) }
  scope :for_terms, -> { joins(:legal_document).where(legal_documents: { document_type: "terms_and_conditions" }) }
  scope :for_privacy, -> { joins(:legal_document).where(legal_documents: { document_type: "privacy_policy" }) }

  # Create acceptance record
  def self.accept!(user:, legal_document:, ip_address: nil, user_agent: nil)
    create!(
      user: user,
      legal_document: legal_document,
      accepted_at: Time.current,
      ip_address: ip_address,
      user_agent: user_agent
    )
  end
end
