# frozen_string_literal: true

class Entity < ApplicationRecord
  include SoftDeletable
  include Auditable

  # Entity types
  ENTITY_TYPES = %w[individual company smsf].freeze

  # Verification statuses
  VERIFICATION_STATUSES = %w[pending submitted under_review verified rejected].freeze

  belongs_to :user

  # Encrypted TFN using Lockbox
  has_encrypted :tfn
  blind_index :tfn

  validates :entity_type, presence: true, inclusion: { in: ENTITY_TYPES }
  validates :name, presence: true
  validates :verification_status, inclusion: { in: VERIFICATION_STATUSES }

  # Company validations
  validates :abn, presence: true, if: :company?
  validates :abn, format: { with: /\A\d{11}\z/, message: "must be 11 digits" }, allow_blank: true

  # SMSF validations
  validates :fund_name, presence: true, if: :smsf?
  validates :fund_abn, presence: true, if: :smsf?
  validates :fund_abn, format: { with: /\A\d{11}\z/, message: "must be 11 digits" }, allow_blank: true

  # Individual validations
  validates :date_of_birth, presence: true, if: :individual?

  # Only one default per user
  validate :only_one_default_per_user, if: :is_default?

  # Scopes
  scope :individuals, -> { where(entity_type: "individual") }
  scope :companies, -> { where(entity_type: "company") }
  scope :smsfs, -> { where(entity_type: "smsf") }
  scope :verified, -> { where(verification_status: "verified") }
  scope :defaults, -> { where(is_default: true) }

  # Callbacks
  before_create :set_default_if_first
  after_save :ensure_only_one_default, if: :saved_change_to_is_default?

  def individual?
    entity_type == "individual"
  end

  def company?
    entity_type == "company"
  end

  def smsf?
    entity_type == "smsf"
  end

  def verified?
    verification_status == "verified"
  end

  def pending_verification?
    verification_status == "pending"
  end

  def display_name
    case entity_type
    when "individual"
      name
    when "company"
      company_name.presence || name
    when "smsf"
      fund_name.presence || name
    end
  end

  def make_default!
    transaction do
      user.entities.where.not(id: id).update_all(is_default: false)
      update!(is_default: true)
    end
  end

  private

  def only_one_default_per_user
    return unless user
    return unless user.entities.where(is_default: true).where.not(id: id).exists?

    errors.add(:is_default, "can only be set for one entity per user")
  end

  def set_default_if_first
    self.is_default = true if user.entities.count.zero?
  end

  def ensure_only_one_default
    return unless is_default?

    user.entities.where.not(id: id).update_all(is_default: false)
  end
end
