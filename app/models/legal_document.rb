# frozen_string_literal: true

class LegalDocument < ApplicationRecord
  include Auditable

  # Document types
  DOCUMENT_TYPES = %w[terms_and_conditions privacy_policy].freeze

  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :published_by, class_name: "User", optional: true

  has_many :legal_document_acceptances, dependent: :destroy
  has_many :users_who_accepted, through: :legal_document_acceptances, source: :user

  validates :document_type, presence: true, inclusion: { in: DOCUMENT_TYPES }
  validates :version, presence: true
  validates :version, uniqueness: { scope: :document_type }
  validates :title, presence: true
  validates :content, presence: true

  # Scopes
  scope :published, -> { where(is_draft: false).where.not(published_at: nil) }
  scope :drafts, -> { where(is_draft: true) }
  scope :current_versions, -> { where(is_current: true) }
  scope :terms, -> { where(document_type: "terms_and_conditions") }
  scope :privacy_policies, -> { where(document_type: "privacy_policy") }
  scope :requiring_acceptance, -> { where(requires_acceptance: true) }

  # Class methods for finding current documents
  def self.current_terms
    terms.current_versions.first
  end

  def self.current_privacy_policy
    privacy_policies.current_versions.first
  end

  # Check if user has accepted this document
  def accepted_by?(user)
    legal_document_acceptances.exists?(user: user)
  end

  # Get acceptance count
  def acceptance_count
    legal_document_acceptances.count
  end

  # Get percentage of users who have accepted (of those required)
  def acceptance_rate
    total_users = User.kept.count
    return 0 if total_users.zero?

    (acceptance_count.to_f / total_users * 100).round(1)
  end

  # Publish this document
  def publish!(publisher)
    return false if published?

    transaction do
      # Unset current for same document type
      self.class.where(document_type: document_type, is_current: true).update_all(is_current: false)

      update!(
        is_draft: false,
        is_current: true,
        published_at: Time.current,
        published_by: publisher
      )
    end

    true
  end

  def published?
    !is_draft && published_at.present?
  end

  def draft?
    is_draft
  end

  def current?
    is_current
  end

  def terms_and_conditions?
    document_type == "terms_and_conditions"
  end

  def privacy_policy?
    document_type == "privacy_policy"
  end

  # Version history
  def previous_version
    self.class
        .where(document_type: document_type)
        .where("created_at < ?", created_at)
        .order(created_at: :desc)
        .first
  end

  def version_history
    self.class
        .where(document_type: document_type)
        .published
        .order(published_at: :desc)
  end
end
