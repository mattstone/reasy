# frozen_string_literal: true

class CoUserInvitation < ApplicationRecord
  include Auditable

  # Relationship types
  RELATIONSHIPS = %w[partner spouse parent child friend advisor other].freeze

  # Invitation statuses
  STATUSES = %w[pending accepted declined expired revoked].freeze

  # Invitation validity period
  EXPIRY_DAYS = 7

  belongs_to :inviter, class_name: "User"
  belongs_to :invitee, class_name: "User", optional: true

  has_one :co_user_relationship, dependent: :nullify

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :invitation_token, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :relationship, inclusion: { in: RELATIONSHIPS }, allow_blank: true

  validate :inviter_can_add_co_users, on: :create
  validate :email_not_inviter

  # Callbacks
  before_validation :generate_token, on: :create
  before_validation :set_expiry, on: :create

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :active, -> { pending.where("invitation_expires_at > ?", Time.current) }
  scope :expired, -> { pending.where("invitation_expires_at <= ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  # Status helpers
  def pending?
    status == "pending"
  end

  def accepted?
    status == "accepted"
  end

  def declined?
    status == "declined"
  end

  def expired?
    status == "expired" || (pending? && invitation_expires_at <= Time.current)
  end

  def revoked?
    status == "revoked"
  end

  def active?
    pending? && !expired?
  end

  # Time helpers
  def days_until_expiry
    return nil unless active?

    ((invitation_expires_at - Time.current) / 1.day).ceil
  end

  def hours_until_expiry
    return nil unless active?

    ((invitation_expires_at - Time.current) / 1.hour).ceil
  end

  # Status transitions
  def accept!(accepting_user)
    return false unless active?
    return false if accepting_user.email.downcase != email.downcase

    transaction do
      update!(
        status: "accepted",
        invitee: accepting_user,
        invitation_accepted_at: Time.current
      )

      # Create the co-user relationship
      CoUserRelationship.create!(
        primary_user: inviter,
        co_user: accepting_user,
        co_user_invitation: self,
        relationship: relationship
      )
    end

    true
  end

  def decline!
    return false unless active?

    update!(status: "declined")
  end

  def revoke!
    return false unless pending?

    update!(status: "revoked")
  end

  def mark_expired!
    return false unless pending? && invitation_expires_at <= Time.current

    update!(status: "expired")
  end

  # Resend invitation
  def resend!
    return false unless pending?

    update!(
      invitation_sent_at: Time.current,
      invitation_expires_at: EXPIRY_DAYS.days.from_now
    )

    # TODO: Send invitation email
    # CoUserInvitationMailer.invitation(self).deliver_later

    true
  end

  # Class methods
  def self.expire_old_invitations!
    expired.find_each(&:mark_expired!)
  end

  def self.find_by_token(token)
    find_by(invitation_token: token)
  end

  private

  def generate_token
    self.invitation_token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiry
    self.invitation_expires_at ||= EXPIRY_DAYS.days.from_now
    self.invitation_sent_at ||= Time.current
  end

  def inviter_can_add_co_users
    return unless inviter
    return if inviter.can_add_co_users?

    errors.add(:inviter, "has reached the maximum number of co-users (2)")
  end

  def email_not_inviter
    return unless inviter
    return unless email.present? && email.downcase == inviter.email.downcase

    errors.add(:email, "cannot invite yourself")
  end
end
