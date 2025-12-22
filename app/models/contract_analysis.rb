# frozen_string_literal: true

class ContractAnalysis < ApplicationRecord
  DOCUMENT_TYPES = %w[
    contract_of_sale
    section_32
    vendor_statement
    zoning_certificate
    strata_report
    building_report
    pest_report
    title_search
    other
  ].freeze

  RISK_LEVELS = %w[low medium high].freeze
  ANALYSIS_STATUSES = %w[pending processing completed failed].freeze

  belongs_to :property_document
  belongs_to :analyzed_by, class_name: "User", optional: true

  validates :analysis_status, presence: true, inclusion: { in: ANALYSIS_STATUSES }
  validates :document_type, inclusion: { in: DOCUMENT_TYPES }, allow_blank: true
  validates :overall_risk_level, inclusion: { in: RISK_LEVELS }, allow_blank: true

  scope :pending, -> { where(analysis_status: "pending") }
  scope :processing, -> { where(analysis_status: "processing") }
  scope :completed, -> { where(analysis_status: "completed") }
  scope :failed, -> { where(analysis_status: "failed") }
  scope :by_risk, ->(level) { where(overall_risk_level: level) }
  scope :high_risk, -> { by_risk("high") }
  scope :recent, -> { order(created_at: :desc) }

  delegate :property, :file, to: :property_document

  # Status helpers
  def pending?
    analysis_status == "pending"
  end

  def processing?
    analysis_status == "processing"
  end

  def completed?
    analysis_status == "completed"
  end

  def failed?
    analysis_status == "failed"
  end

  # Risk level helpers
  def low_risk?
    overall_risk_level == "low"
  end

  def medium_risk?
    overall_risk_level == "medium"
  end

  def high_risk?
    overall_risk_level == "high"
  end

  # State transitions
  def start_processing!
    update!(analysis_status: "processing")
  end

  def complete!(summary:, risk_level:, extracted_terms: {}, unusual_clauses: [], recommendations: nil, tokens_used: 0)
    update!(
      analysis_status: "completed",
      summary: summary,
      overall_risk_level: risk_level,
      extracted_terms: extracted_terms,
      unusual_clauses: unusual_clauses,
      recommendations: recommendations,
      tokens_used: tokens_used
    )
  end

  def fail!(error_message)
    update!(
      analysis_status: "failed",
      error_message: error_message
    )
  end

  # Clause helpers
  def unusual_clause_count
    unusual_clauses.is_a?(Array) ? unusual_clauses.size : 0
  end

  def has_unusual_clauses?
    unusual_clause_count.positive?
  end

  def high_risk_clauses
    return [] unless unusual_clauses.is_a?(Array)
    unusual_clauses.select { |c| c["risk_level"] == "high" }
  end

  def medium_risk_clauses
    return [] unless unusual_clauses.is_a?(Array)
    unusual_clauses.select { |c| c["risk_level"] == "medium" }
  end

  def low_risk_clauses
    return [] unless unusual_clauses.is_a?(Array)
    unusual_clauses.select { |c| c["risk_level"] == "low" }
  end

  # Extracted term helpers
  def parties
    extracted_terms["parties"] || {}
  end

  def price
    extracted_terms["price"]
  end

  def settlement_date
    extracted_terms["settlement_date"]
  end

  def deposit_amount
    extracted_terms["deposit_amount"]
  end

  def special_conditions
    extracted_terms["special_conditions"] || []
  end

  # Display helpers
  def risk_badge_class
    case overall_risk_level
    when "low" then "badge-success"
    when "medium" then "badge-warning"
    when "high" then "badge-danger"
    else "badge-secondary"
    end
  end

  def risk_display
    overall_risk_level&.titleize || "Unknown"
  end

  def document_type_display
    document_type&.titleize&.gsub("_", " ") || "Unknown"
  end
end
