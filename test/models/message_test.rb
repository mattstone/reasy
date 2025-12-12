# frozen_string_literal: true

require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "factory creates valid message" do
    message = build(:message)
    assert message.valid?, message.errors.full_messages.join(", ")
  end

  test "requires conversation" do
    message = build(:message, conversation: nil)
    assert_not message.valid?
    assert_includes message.errors[:conversation], "must exist"
  end

  test "requires sender" do
    message = build(:message, sender: nil)
    assert_not message.valid?
    assert_includes message.errors[:sender], "must exist"
  end

  test "requires content" do
    message = build(:message, content: nil)
    assert_not message.valid?
    assert_includes message.errors[:content], "can't be blank"
  end

  test "text? returns true for text messages" do
    message = build(:message, message_type: "text")
    assert message.text?
  end

  test "system? returns true for system messages" do
    message = build(:message, :system)
    assert message.system?
  end

  test "ai_generated? returns true for AI messages" do
    message = build(:message, :ai_generated)
    assert message.ai_generated?
  end

  test "edited? returns true when edited_at present" do
    message = build(:message, :edited)
    assert message.edited?
  end

  test "edit! updates content and sets edited_at" do
    message = create(:message, content: "Original")
    message.edit!("Updated")

    assert_equal "Updated", message.content
    assert message.edited?
  end

  test "edit! returns false for system messages" do
    message = create(:message, :system)
    result = message.edit!("New content")

    assert_not result
    assert_not_equal "New content", message.content
  end

  test "edit! returns false for AI messages" do
    message = create(:message, :ai_generated)
    result = message.edit!("New content")

    assert_not result
    assert_not_equal "New content", message.content
  end

  test "soft delete keeps message but marks deleted" do
    message = create(:message)
    message.destroy

    assert message.deleted?
    assert_not_nil message.deleted_at
    assert Message.with_deleted.exists?(id: message.id)
  end

  test "chronological scope orders by created_at asc" do
    conversation = create(:conversation, participants_count: 0)
    sender = create(:user)
    conversation.add_participant!(sender)

    old = create(:message, conversation: conversation, sender: sender, created_at: 1.hour.ago)
    new = create(:message, conversation: conversation, sender: sender, created_at: Time.current)

    messages = conversation.messages.chronological
    assert_equal old, messages.first
    assert_equal new, messages.last
  end
end
