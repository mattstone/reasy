# frozen_string_literal: true

class AIConversation < ApplicationRecord
  include Auditable

  # Available assistants
  ASSISTANTS = AIVoiceSetting::ASSISTANTS

  belongs_to :user

  has_many :ai_messages, dependent: :destroy

  validates :assistant, presence: true, inclusion: { in: ASSISTANTS }
  validates :started_at, presence: true

  # Scopes
  scope :by_assistant, ->(assistant) { where(assistant: assistant) }
  scope :for_context, ->(type, id) { where(context_type: type, context_id: id) }
  scope :recent, -> { order(started_at: :desc) }
  scope :today, -> { where(started_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :this_week, -> { where(started_at: 1.week.ago..Time.current) }
  scope :active, -> { where(ended_at: nil) }
  scope :completed, -> { where.not(ended_at: nil) }
  scope :rated, -> { where.not(user_rating: nil) }
  scope :unrated, -> { where(user_rating: nil) }

  # Callbacks
  before_validation :set_started_at, on: :create

  # Create a new conversation
  def self.start(user:, assistant:, context_type: nil, context_id: nil)
    create!(
      user: user,
      assistant: assistant,
      context_type: context_type,
      context_id: context_id,
      started_at: Time.current
    )
  end

  # Add a message to the conversation
  def add_message(role:, content:, tokens_used: nil, model_version: nil, response_time_ms: nil, prompt_context: {})
    message = ai_messages.create!(
      role: role,
      content: content,
      tokens_used: tokens_used,
      model_version: model_version,
      response_time_ms: response_time_ms,
      prompt_context: prompt_context
    )

    # Update conversation stats
    increment!(:message_count)
    increment!(:total_tokens, tokens_used.to_i) if tokens_used

    message
  end

  # End the conversation
  def complete!
    update!(ended_at: Time.current)
  end

  # Rate the conversation
  def rate!(rating, feedback: nil)
    update!(
      user_rating: rating,
      user_feedback: feedback
    )
  end

  # Get voice settings for this conversation's assistant
  def voice_settings
    @voice_settings ||= AIVoiceSetting.for(assistant)
  end

  # Duration helpers
  def duration_seconds
    return nil unless ended_at

    (ended_at - started_at).to_i
  end

  def duration_minutes
    return nil unless duration_seconds

    (duration_seconds / 60.0).round(1)
  end

  # Context helpers
  def has_context?
    context_type.present? && context_id.present?
  end

  def context_object
    return nil unless has_context?

    @context_object ||= context_type.constantize.find_by(id: context_id)
  rescue NameError
    nil
  end

  # Message helpers
  def user_messages
    ai_messages.where(role: "user")
  end

  def assistant_messages
    ai_messages.where(role: "assistant")
  end

  def system_messages
    ai_messages.where(role: "system")
  end

  def last_message
    ai_messages.order(created_at: :desc).first
  end

  def preview
    last_user_message = user_messages.order(created_at: :asc).first
    last_user_message&.content&.truncate(100)
  end

  # Analytics helpers
  def average_response_time_ms
    return nil if assistant_messages.empty?

    assistant_messages.average(:response_time_ms)&.round
  end

  def tokens_per_message
    return nil if message_count.zero?

    (total_tokens.to_f / message_count).round
  end

  private

  def set_started_at
    self.started_at ||= Time.current
  end
end
