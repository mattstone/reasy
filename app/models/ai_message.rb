# frozen_string_literal: true

class AIMessage < ApplicationRecord
  # Message roles
  ROLES = %w[system user assistant].freeze

  belongs_to :ai_conversation

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :content, presence: true

  # Scopes
  scope :by_role, ->(role) { where(role: role) }
  scope :system_messages, -> { where(role: "system") }
  scope :user_messages, -> { where(role: "user") }
  scope :assistant_messages, -> { where(role: "assistant") }
  scope :chronological, -> { order(created_at: :asc) }
  scope :recent_first, -> { order(created_at: :desc) }

  # Delegate user to conversation
  delegate :user, to: :ai_conversation

  def system?
    role == "system"
  end

  def user?
    role == "user"
  end

  def assistant?
    role == "assistant"
  end

  # Truncated content for previews
  def preview(length: 100)
    content.truncate(length)
  end

  # Get the model used (for assistant messages)
  def model_name
    return nil unless assistant?

    model_version&.split("/")&.last || model_version
  end
end
