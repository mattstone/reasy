# frozen_string_literal: true

class Notification < ApplicationRecord
  NOTIFICATION_TYPES = %w[
    offer_received
    offer_accepted
    offer_rejected
    offer_countered
    offer_expired
    offer_withdrawn
    property_view
    property_enquiry
    property_loved
    transaction_update
    document_uploaded
    message_received
    review_received
    review_published
    kyc_status_changed
    subscription_reminder
    system_announcement
  ].freeze

  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :notification_type, presence: true, inclusion: { in: NOTIFICATION_TYPES }
  validates :title, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }
  scope :pending_email, -> { where(send_email: true, email_sent_at: nil) }
  scope :pending_push, -> { where(send_push: true, push_sent_at: nil) }
  scope :pending_sms, -> { where(send_sms: true, sms_sent_at: nil) }

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  def mark_read!
    update!(read_at: Time.current) unless read?
  end

  def mark_unread!
    update!(read_at: nil) if read?
  end

  # Delivery methods
  def deliver_email!
    return if email_sent_at.present?
    return unless send_email?

    # NotificationMailer.notification(self).deliver_later
    update!(email_sent_at: Time.current)
  end

  def deliver_push!
    return if push_sent_at.present?
    return unless send_push?

    # PushNotificationService.deliver(self)
    update!(push_sent_at: Time.current)
  end

  def deliver_sms!
    return if sms_sent_at.present?
    return unless send_sms?

    # SmsService.deliver(self)
    update!(sms_sent_at: Time.current)
  end

  def deliver_all!
    deliver_email!
    deliver_push!
    deliver_sms!
  end

  # Factory methods
  class << self
    def notify_offer_received!(property:, offer:)
      create!(
        user: property.user,
        notification_type: "offer_received",
        title: "New offer received",
        body: "You've received an offer of #{format_currency(offer.amount_cents)} on #{property.short_address}",
        notifiable: offer,
        action_url: "/seller/offers/#{offer.id}",
        action_text: "View Offer"
      )
    end

    def notify_offer_response!(offer:, status:)
      type = "offer_#{status}"
      messages = {
        "accepted" => "Your offer has been accepted!",
        "rejected" => "Your offer was not accepted",
        "countered" => "The seller has made a counter-offer"
      }

      create!(
        user: offer.buyer,
        notification_type: type,
        title: messages[status] || "Offer #{status}",
        body: "Your offer on #{offer.property.short_address} has been #{status}",
        notifiable: offer,
        action_url: "/buyer/offers/#{offer.id}",
        action_text: "View Details"
      )
    end

    def notify_message_received!(message:, recipient:)
      create!(
        user: recipient,
        notification_type: "message_received",
        title: "New message from #{message.sender.name}",
        body: message.content.truncate(100),
        notifiable: message.conversation,
        action_url: "/messages/#{message.conversation_id}",
        action_text: "Reply"
      )
    end

    private

    def format_currency(cents)
      return "N/A" unless cents

      "$#{(cents / 100).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    end
  end
end
