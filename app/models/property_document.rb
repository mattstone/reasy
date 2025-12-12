# frozen_string_literal: true

class PropertyDocument < ApplicationRecord
  include SoftDeletable
  include Auditable

  DOCUMENT_TYPES = %w[
    contract
    building_report
    pest_report
    strata_report
    title_search
    survey
    zoning_certificate
    flood_certificate
    bushfire_certificate
    pool_certificate
    gas_certificate
    electrical_certificate
    asbestos_report
    planning_certificate
    section_32
    other
  ].freeze

  belongs_to :property
  belongs_to :uploaded_by, class_name: "User"

  has_one_attached :file

  validates :document_type, presence: true, inclusion: { in: DOCUMENT_TYPES }
  validates :title, presence: true

  scope :visible_to_buyers, -> { where(visible_to_buyers: true) }
  scope :requires_nda, -> { where(requires_nda: true) }
  scope :by_type, ->(type) { where(document_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  def accessible_by?(user)
    return true if property.user == user
    return visible_to_buyers? unless requires_nda?

    # If requires NDA, check if user has signed NDA
    # This would be implemented with NDA acceptance tracking
    visible_to_buyers?
  end

  def contract?
    document_type == "contract"
  end

  def inspection_report?
    document_type.in?(%w[building_report pest_report])
  end

  def certificate?
    document_type.end_with?("_certificate")
  end
end
