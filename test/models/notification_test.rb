# frozen_string_literal: true

require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "factory creates valid notification" do
    notification = build(:notification)
    assert notification.valid?, notification.errors.full_messages.join(", ")
  end

  test "requires user" do
    notification = build(:notification, user: nil)
    assert_not notification.valid?
    assert_includes notification.errors[:user], "must exist"
  end

  test "requires notification_type" do
    notification = build(:notification, notification_type: nil)
    assert_not notification.valid?
    assert_includes notification.errors[:notification_type], "can't be blank"
  end

  test "requires valid notification_type" do
    notification = build(:notification, notification_type: "invalid")
    assert_not notification.valid?
    assert_includes notification.errors[:notification_type], "is not included in the list"
  end

  test "requires title" do
    notification = build(:notification, title: nil)
    assert_not notification.valid?
    assert_includes notification.errors[:title], "can't be blank"
  end

  test "read? returns true when read_at present" do
    notification = build(:notification, :read)
    assert notification.read?
  end

  test "unread? returns true when read_at nil" do
    notification = build(:notification, :unread)
    assert notification.unread?
  end

  test "mark_read! sets read_at" do
    notification = create(:notification, :unread)
    notification.mark_read!

    assert notification.read?
    assert_not_nil notification.read_at
  end

  test "mark_read! does nothing if already read" do
    notification = create(:notification, :read)
    original_read_at = notification.read_at

    notification.mark_read!
    assert_equal original_read_at, notification.read_at
  end

  test "mark_unread! clears read_at" do
    notification = create(:notification, :read)
    notification.mark_unread!

    assert notification.unread?
    assert_nil notification.read_at
  end

  test "unread scope returns unread notifications" do
    unread = create(:notification, :unread)
    read = create(:notification, :read)

    assert_includes Notification.unread, unread
    assert_not_includes Notification.unread, read
  end

  test "recent scope orders by created_at desc" do
    old = create(:notification, created_at: 1.day.ago)
    new = create(:notification, created_at: 1.hour.ago)

    notifications = Notification.recent
    assert_equal new, notifications.first
  end

  test "notify_offer_received! creates notification" do
    property = create(:property, :active, :with_pricing)
    offer = create(:offer, :submitted, property: property)

    notification = Notification.notify_offer_received!(property: property, offer: offer)

    assert_equal property.user, notification.user
    assert_equal "offer_received", notification.notification_type
    assert_equal offer, notification.notifiable
  end

  test "deliver_email! marks email as sent" do
    notification = create(:notification, :email_pending)
    notification.deliver_email!

    assert_not_nil notification.email_sent_at
  end

  test "deliver_email! does nothing if already sent" do
    notification = create(:notification, :email_sent)
    original_sent_at = notification.email_sent_at

    notification.deliver_email!
    assert_equal original_sent_at, notification.email_sent_at
  end
end
