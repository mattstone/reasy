# frozen_string_literal: true

# Caches AI-generated analysis for a specific property and user combination.
# Analyses are personalized based on user preferences and expire after a period.
class PropertyAnalysis < ApplicationRecord
  STATUSES = %w[pending processing completed failed expired].freeze
  DEFAULT_EXPIRY = 7.days

  belongs_to :property
  belongs_to :user

  validates :status, inclusion: { in: STATUSES }

  # Scopes
  scope :valid, -> { where("expires_at > ?", Time.current).where(status: "completed") }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :pending, -> { where(status: "pending") }
  scope :processing, -> { where(status: "processing") }
  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }
  scope :for_property, ->(property) { where(property: property) }
  scope :for_user, ->(user) { where(user: user) }

  # Find a valid, non-expired analysis for a property/user combo
  def self.find_valid(property:, user:)
    for_property(property)
      .for_user(user)
      .valid
      .order(created_at: :desc)
      .first
  end

  # Find or create an analysis record (for job queuing)
  def self.find_or_create_pending(property:, user:)
    # Check for existing valid analysis
    existing = find_valid(property: property, user: user)
    return existing if existing

    # Check for in-progress analysis
    in_progress = for_property(property)
                  .for_user(user)
                  .where(status: %w[pending processing])
                  .first
    return in_progress if in_progress

    # Create new pending analysis
    create!(
      property: property,
      user: user,
      status: "pending",
      expires_at: DEFAULT_EXPIRY.from_now
    )
  end

  # Status helpers
  def pending?
    status == "pending"
  end

  def processing?
    status == "processing"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def valid?
    completed? && !expired?
  end

  # Start processing
  def start_processing!
    update!(status: "processing")
  end

  # Complete with analysis results
  def complete!(match_score:, strengths:, considerations:, suggestion:, ai_badges:, context_snapshot: {}, model_version: nil)
    update!(
      status: "completed",
      match_score: match_score,
      strengths: strengths,
      considerations: considerations,
      suggestion: suggestion,
      ai_badges: ai_badges,
      context_snapshot: context_snapshot,
      model_version: model_version,
      analyzed_at: Time.current,
      expires_at: DEFAULT_EXPIRY.from_now
    )
  end

  # Mark as failed
  def fail!(error_message = nil)
    update!(
      status: "failed",
      context_snapshot: context_snapshot.merge(error: error_message)
    )
  end

  # Refresh the analysis (queue a new job)
  def refresh!
    update!(
      status: "pending",
      expires_at: DEFAULT_EXPIRY.from_now
    )
    GeneratePropertyAnalysisJob.perform_later(property_id, user_id)
  end

  # Get the AI agent name based on user preference
  def agent_name
    user.preferred_agent_name || "Stevie"
  end

  # Format strengths for display
  def formatted_strengths
    return [] unless strengths.is_a?(Array)

    strengths.map do |s|
      s.is_a?(Hash) ? s["message"] || s[:message] : s.to_s
    end
  end

  # Format considerations for display
  def formatted_considerations
    return [] unless considerations.is_a?(Array)

    considerations.map do |c|
      c.is_a?(Hash) ? c["message"] || c[:message] : c.to_s
    end
  end

  # Get badges array
  def formatted_badges
    return [] unless ai_badges.is_a?(Array)

    ai_badges.map do |badge|
      badge.symbolize_keys
    end
  end

  # Score quality description
  def match_quality
    return nil unless match_score

    case match_score
    when 80..100 then :excellent
    when 65..79 then :good
    when 50..64 then :moderate
    when 30..49 then :low
    else :poor
    end
  end

  def match_quality_label
    case match_quality
    when :excellent then "Excellent Match"
    when :good then "Good Match"
    when :moderate then "Moderate Match"
    when :low then "Low Match"
    when :poor then "Poor Match"
    else "Unknown"
    end
  end
end
