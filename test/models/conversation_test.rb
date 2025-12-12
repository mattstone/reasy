# frozen_string_literal: true

require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  test "factory creates valid conversation" do
    conversation = build(:conversation)
    assert conversation.valid?, conversation.errors.full_messages.join(", ")
  end

  test "participant? returns true for participant" do
    conversation = create(:conversation, participants_count: 0)
    user = create(:user)
    conversation.add_participant!(user)

    assert conversation.participant?(user)
  end

  test "participant? returns false for non-participant" do
    conversation = create(:conversation, participants_count: 0)
    user = create(:user)

    assert_not conversation.participant?(user)
  end

  test "add_participant! adds user to conversation" do
    conversation = create(:conversation, participants_count: 0)
    user = create(:user)

    assert_difference "ConversationParticipant.count", 1 do
      conversation.add_participant!(user)
    end

    assert conversation.participant?(user)
  end

  test "add_participant! does not duplicate" do
    conversation = create(:conversation, participants_count: 0)
    user = create(:user)

    conversation.add_participant!(user)

    assert_no_difference "ConversationParticipant.count" do
      conversation.add_participant!(user)
    end
  end

  test "send_message! creates message" do
    conversation = create(:conversation, participants_count: 0)
    sender = create(:user)
    conversation.add_participant!(sender)

    message = conversation.send_message!(sender: sender, content: "Hello!")

    assert_equal "Hello!", message.content
    assert_equal sender, message.sender
    assert_equal 1, conversation.reload.message_count
  end

  test "send_message! does not allow non-participants" do
    conversation = create(:conversation, participants_count: 0)
    non_participant = create(:user)

    result = conversation.send_message!(sender: non_participant, content: "Hello!")
    assert_nil result
  end

  test "unread_count_for returns correct count" do
    conversation = create(:conversation, participants_count: 0)
    user1 = create(:user)
    user2 = create(:user)
    conversation.add_participant!(user1)
    conversation.add_participant!(user2)

    conversation.send_message!(sender: user1, content: "Message 1")
    conversation.send_message!(sender: user1, content: "Message 2")

    assert_equal 2, conversation.unread_count_for(user2)
  end

  test "mark_read_for! updates last_read_at" do
    conversation = create(:conversation, participants_count: 0)
    user = create(:user)
    conversation.add_participant!(user)

    conversation.mark_read_for!(user)

    participant = conversation.conversation_participants.find_by(user: user)
    assert_not_nil participant.last_read_at
  end

  test "between creates new conversation if none exists" do
    user1 = create(:user)
    user2 = create(:user)

    conversation = Conversation.between(user1, user2)

    assert conversation.persisted?
    assert conversation.participant?(user1)
    assert conversation.participant?(user2)
  end

  test "between returns existing conversation" do
    user1 = create(:user)
    user2 = create(:user)

    conversation1 = Conversation.between(user1, user2)
    conversation2 = Conversation.between(user1, user2)

    assert_equal conversation1, conversation2
  end

  test "other_participants excludes specified user" do
    conversation = create(:conversation, participants_count: 0)
    user1 = create(:user)
    user2 = create(:user)
    conversation.add_participant!(user1)
    conversation.add_participant!(user2)

    others = conversation.other_participants(user1)

    assert_includes others, user2
    assert_not_includes others, user1
  end
end
