# frozen_string_literal: true

class User < ApplicationRecord
  include SoftDeletable
  include Auditable

  # Devise modules
  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
         :validatable, :confirmable, :lockable, :trackable

  # Roles constants
  ROLES = %w[buyer seller service_provider admin].freeze

  # Preferred AI agent choices
  PREFERRED_AGENTS = %w[stevie evie].freeze

  # Level tiers for gamification
  LEVEL_TIERS = {
    1 => { points: 0, title: "Property Newcomer" },
    2 => { points: 100, title: "Home Seeker" },
    3 => { points: 250, title: "Property Explorer" },
    4 => { points: 500, title: "Transaction Starter" },
    5 => { points: 800, title: "Deal Maker" },
    6 => { points: 1200, title: "Property Pro" },
    7 => { points: 1800, title: "Transaction Expert" },
    8 => { points: 2500, title: "Reasy Champion" },
    9 => { points: 3500, title: "Property Master" },
    10 => { points: 5000, title: "Reasy Legend" }
  }.freeze

  # KYC status values
  KYC_STATUSES = %w[pending submitted under_review verified rejected].freeze

  # Subscription status values
  SUBSCRIPTION_STATUSES = %w[trial active past_due cancelled expired].freeze

  # Associations
  has_many :entities, dependent: :destroy
  has_one :buyer_profile, dependent: :destroy
  has_one :seller_profile, dependent: :destroy
  has_one :service_provider_profile, dependent: :destroy

  # Co-user relationships
  has_many :co_user_invitations_sent, class_name: "CoUserInvitation", foreign_key: :inviter_id, dependent: :destroy
  has_many :co_user_invitations_received, class_name: "CoUserInvitation", foreign_key: :invitee_id, dependent: :nullify

  has_many :co_user_relationships_as_primary, class_name: "CoUserRelationship", foreign_key: :primary_user_id, dependent: :destroy
  has_many :co_users, through: :co_user_relationships_as_primary, source: :co_user

  has_many :co_user_relationships_as_co_user, class_name: "CoUserRelationship", foreign_key: :co_user_id, dependent: :destroy
  has_many :primary_users, through: :co_user_relationships_as_co_user, source: :primary_user

  # AI conversations
  has_many :ai_conversations, dependent: :destroy

  # Reviews
  has_many :reviews_given, class_name: "Review", foreign_key: :reviewer_id, dependent: :destroy
  has_many :reviews_received, class_name: "Review", foreign_key: :reviewee_id, dependent: :destroy

  # Legal document acceptances
  has_many :legal_document_acceptances, dependent: :destroy
  has_many :accepted_legal_documents, through: :legal_document_acceptances, source: :legal_document

  # Audit logs
  has_many :audit_logs, dependent: :nullify

  # Active Storage
  has_one_attached :avatar

  # Properties
  has_many :properties, dependent: :destroy
  has_many :property_loves, dependent: :destroy
  has_many :loved_properties, through: :property_loves, source: :property
  has_many :property_enquiries, dependent: :destroy
  has_many :property_views, dependent: :nullify

  # Offers and Transactions
  has_many :offers_made, class_name: "Offer", foreign_key: :buyer_id, dependent: :destroy
  has_many :transactions_as_buyer, class_name: "Transaction", foreign_key: :buyer_id, dependent: :nullify
  has_many :transactions_as_seller, class_name: "Transaction", foreign_key: :seller_id, dependent: :nullify

  # Notifications
  has_many :notifications, dependent: :destroy

  # Messaging
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :messages_sent, class_name: "Message", foreign_key: :sender_id, dependent: :nullify

  # Saved searches
  has_many :saved_searches, dependent: :destroy

  # AI Property analyses
  has_many :property_analyses, dependent: :destroy

  # Journey system - checklist progress and achievements
  has_many :user_checklist_progresses, dependent: :destroy
  has_many :user_achievements, dependent: :destroy
  has_many :completed_checklist_items, through: :user_checklist_progresses, source: :checklist_item

  # Validations
  validates :name, presence: true
  validates :roles, presence: true
  validates :kyc_status, inclusion: { in: KYC_STATUSES }
  validates :subscription_status, inclusion: { in: SUBSCRIPTION_STATUSES }
  validates :phone, phone: { allow_blank: true, countries: :phone_country_code }
  validates :preferred_agent, inclusion: { in: PREFERRED_AGENTS }, allow_blank: true

  # Callbacks
  before_validation :set_default_roles, on: :create
  before_validation :set_trial_period, on: :create

  # Scopes
  scope :buyers, -> { where("'buyer' = ANY(roles)") }
  scope :sellers, -> { where("'seller' = ANY(roles)") }
  scope :service_providers, -> { where("'service_provider' = ANY(roles)") }
  scope :admins, -> { where("'admin' = ANY(roles)") }
  scope :verified, -> { where(kyc_status: "verified") }
  scope :active_subscription, -> { where(subscription_status: %w[trial active]) }

  # Role helper methods
  def buyer?
    roles.include?("buyer")
  end

  def seller?
    roles.include?("seller")
  end

  def service_provider?
    roles.include?("service_provider")
  end

  def admin?
    roles.include?("admin")
  end

  def add_role(role)
    return unless ROLES.include?(role.to_s)
    return if roles.include?(role.to_s)

    self.roles = roles + [role.to_s]
    save
  end

  def remove_role(role)
    self.roles = roles - [role.to_s]
    save
  end

  # Profile helpers
  def ensure_buyer_profile
    buyer_profile || create_buyer_profile
  end

  def ensure_seller_profile
    seller_profile || create_seller_profile
  end

  def ensure_service_provider_profile(business_name:, service_type:)
    service_provider_profile || create_service_provider_profile(
      business_name: business_name,
      service_type: service_type
    )
  end

  # Entity helpers
  def default_entity
    entities.find_by(is_default: true) || entities.first
  end

  def individual_entity
    entities.find_by(entity_type: "individual")
  end

  def company_entities
    entities.where(entity_type: "company")
  end

  def smsf_entities
    entities.where(entity_type: "smsf")
  end

  # KYC helpers
  def kyc_verified?
    kyc_status == "verified"
  end

  def kyc_pending?
    kyc_status == "pending"
  end

  # Subscription helpers
  def active_subscription?
    subscription_status.in?(%w[trial active])
  end

  def trial?
    subscription_status == "trial"
  end

  def trial_expired?
    trial? && trial_ends_at.present? && trial_ends_at < Time.current
  end

  # Co-user helpers
  def can_add_co_users?
    co_user_relationships_as_primary.active.count < 2
  end

  def has_co_user_access_to?(other_user)
    co_user_relationships_as_co_user.active.exists?(primary_user: other_user)
  end

  # Terms acceptance helpers
  def accepted_current_terms?
    return false unless terms_accepted_at.present?

    current_terms = LegalDocument.current_terms
    return true unless current_terms # No terms required yet

    legal_document_acceptances.exists?(legal_document: current_terms)
  end

  def accepted_current_privacy_policy?
    return false unless privacy_policy_accepted_at.present?

    current_policy = LegalDocument.current_privacy_policy
    return true unless current_policy

    legal_document_acceptances.exists?(legal_document: current_policy)
  end

  def needs_to_accept_legal_documents?
    !accepted_current_terms? || !accepted_current_privacy_policy?
  end

  # Journey & Agent helpers
  def preferred_agent_name
    case preferred_agent
    when "stevie" then "Stevie"
    when "evie" then "Evie"
    else nil
    end
  end

  def has_preferred_agent?
    preferred_agent.present?
  end

  def stevie?
    preferred_agent == "stevie"
  end

  def evie?
    preferred_agent == "evie"
  end

  # Level helpers
  def level_progress_percentage
    current_tier = LEVEL_TIERS[journey_level]
    next_tier = LEVEL_TIERS[journey_level + 1]

    return 100 if next_tier.nil? # Max level

    current_threshold = current_tier[:points]
    next_threshold = next_tier[:points]
    points_in_level = journey_points - current_threshold
    points_needed = next_threshold - current_threshold

    ((points_in_level.to_f / points_needed) * 100).round
  end

  def points_to_next_level
    next_tier = LEVEL_TIERS[journey_level + 1]
    return 0 if next_tier.nil?

    [next_tier[:points] - journey_points, 0].max
  end

  def recalculate_level!
    new_level = calculate_level_from_points
    return if new_level == journey_level

    old_level = journey_level
    new_title = LEVEL_TIERS[new_level][:title]

    update!(
      journey_level: new_level,
      journey_title: new_title
    )

    # Award level up achievement if leveling up
    if new_level > old_level
      UserAchievement.award_level_up!(self, new_level, new_title)
    end
  end

  # Checklist progress helpers
  def checklist_progress_for(journey_type, context = nil)
    scope = user_checklist_progresses.for_journey(journey_type)
    scope = scope.where(context: context) if context
    scope
  end

  def completed_items_for(journey_type, context = nil)
    checklist_progress_for(journey_type, context).completed
  end

  def pending_items_for(journey_type, context = nil)
    checklist_progress_for(journey_type, context).pending
  end

  def journey_completion_percentage(journey_type, context = nil)
    checklists = JourneyChecklist.for_journey(journey_type)
    total_items = checklists.sum { |c| c.checklist_items.count }
    return 0 if total_items.zero?

    completed = completed_items_for(journey_type, context).count
    (completed.to_f / total_items * 100).round
  end

  # Achievement helpers
  def recent_achievements(limit = 5)
    user_achievements.recent.limit(limit)
  end

  def total_achievement_points
    user_achievements.sum(:points_earned)
  end

  private

  def calculate_level_from_points
    LEVEL_TIERS.reverse_each do |level, tier|
      return level if journey_points >= tier[:points]
    end
    1
  end

  def set_default_roles
    self.roles = ["buyer"] if roles.blank?
  end

  def set_trial_period
    return if subscription_started_at.present?

    self.subscription_status = "trial"
    self.trial_ends_at = 24.hours.from_now
  end
end
