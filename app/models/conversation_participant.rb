# frozen_string_literal: true

class ConversationParticipant < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  validates :user_id, uniqueness: { scope: :conversation_id }

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  scope :muted, -> { where(muted: true) }

  def archive!
    update!(archived: true)
  end

  def unarchive!
    update!(archived: false)
  end

  def mute!
    update!(muted: true)
  end

  def unmute!
    update!(muted: false)
  end

  def unread_count
    return 0 if last_read_at.nil?

    conversation.messages.where("created_at > ?", last_read_at).count
  end
end
