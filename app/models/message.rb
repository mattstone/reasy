# frozen_string_literal: true

class Message < ApplicationRecord
  include SoftDeletable

  MESSAGE_TYPES = %w[text system ai_generated].freeze

  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  validates :content, presence: true
  validates :message_type, inclusion: { in: MESSAGE_TYPES }

  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :by_sender, ->(user) { where(sender: user) }
  scope :system_messages, -> { where(message_type: "system") }
  scope :ai_messages, -> { where(message_type: "ai_generated") }

  after_create :update_conversation_timestamp

  def text?
    message_type == "text"
  end

  def system?
    message_type == "system"
  end

  def ai_generated?
    message_type == "ai_generated"
  end

  def edited?
    edited_at.present?
  end

  def edit!(new_content)
    return false if system? || ai_generated?

    update!(
      content: new_content,
      edited_at: Time.current
    )
  end

  private

  def update_conversation_timestamp
    conversation.update!(last_message_at: created_at)
  end
end
