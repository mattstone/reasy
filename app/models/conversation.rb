# frozen_string_literal: true

class Conversation < ApplicationRecord
  belongs_to :property, optional: true

  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :messages, dependent: :destroy

  scope :recent, -> { order(last_message_at: :desc) }
  scope :with_unread_for, ->(user) {
    joins(:conversation_participants)
      .where(conversation_participants: { user_id: user.id })
      .where("conversations.last_message_at > conversation_participants.last_read_at OR conversation_participants.last_read_at IS NULL")
  }

  def participant?(user)
    participants.include?(user)
  end

  def other_participants(user)
    participants.where.not(id: user.id)
  end

  def unread_count_for(user)
    participant = conversation_participants.find_by(user: user)
    return 0 unless participant

    if participant.last_read_at.nil?
      messages.count
    else
      messages.where("created_at > ?", participant.last_read_at).count
    end
  end

  def mark_read_for!(user)
    conversation_participants.find_by(user: user)&.update!(last_read_at: Time.current)
  end

  def add_participant!(user)
    conversation_participants.find_or_create_by!(user: user)
  end

  def remove_participant!(user)
    conversation_participants.find_by(user: user)&.update!(archived: true)
  end

  def send_message!(sender:, content:, message_type: "text")
    return unless participant?(sender)

    message = messages.create!(
      sender: sender,
      content: content,
      message_type: message_type
    )

    update!(
      last_message_at: Time.current,
      message_count: message_count + 1
    )

    # Notify other participants
    other_participants(sender).each do |recipient|
      Notification.notify_message_received!(message: message, recipient: recipient)
    end

    message
  end

  # Find or create a conversation between users
  def self.between(user1, user2, property: nil)
    # Find existing conversation
    existing = joins(:conversation_participants)
      .where(conversation_participants: { user_id: [user1.id, user2.id] })
      .group("conversations.id")
      .having("COUNT(DISTINCT conversation_participants.user_id) = 2")
      .where(property_id: property&.id)
      .first

    return existing if existing

    # Create new conversation
    conversation = create!(property: property)
    conversation.add_participant!(user1)
    conversation.add_participant!(user2)
    conversation
  end
end
