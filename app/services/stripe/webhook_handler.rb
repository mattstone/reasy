# frozen_string_literal: true

module Stripe
  class WebhookHandler
    def initialize(payload:, signature:)
      @payload = payload
      @signature = signature
    end

    def process!
      event = construct_event
      return { error: "Invalid signature" } unless event

      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "customer.subscription.created"
        handle_subscription_created(event.data.object)
      when "customer.subscription.updated"
        handle_subscription_updated(event.data.object)
      when "customer.subscription.deleted"
        handle_subscription_deleted(event.data.object)
      when "invoice.payment_succeeded"
        handle_payment_succeeded(event.data.object)
      when "invoice.payment_failed"
        handle_payment_failed(event.data.object)
      when "customer.subscription.trial_will_end"
        handle_trial_ending(event.data.object)
      else
        Rails.logger.info "Unhandled Stripe event: #{event.type}"
      end

      { success: true, event_type: event.type }
    rescue StandardError => e
      Rails.logger.error "Webhook error: #{e.message}"
      { error: e.message }
    end

    private

    def construct_event
      ::Stripe::Webhook.construct_event(
        @payload,
        @signature,
        Rails.configuration.stripe.webhook_secret
      )
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid JSON: #{e.message}"
      nil
    rescue ::Stripe::SignatureVerificationError => e
      Rails.logger.error "Invalid signature: #{e.message}"
      nil
    end

    def handle_checkout_completed(session)
      user = find_user_from_session(session)
      return unless user

      if session.mode == "subscription" && session.subscription.present?
        user.update!(
          stripe_subscription_id: session.subscription,
          subscription_status: "active",
          subscription_started_at: Time.current
        )
      end
    end

    def handle_subscription_created(subscription)
      user = find_user_from_customer(subscription.customer)
      return unless user

      user.update!(
        stripe_subscription_id: subscription.id,
        subscription_status: subscription.status == "trialing" ? "trial" : "active",
        subscription_started_at: Time.current,
        trial_ends_at: subscription.trial_end.present? ? Time.at(subscription.trial_end) : nil
      )
    end

    def handle_subscription_updated(subscription)
      user = find_user_from_customer(subscription.customer)
      return unless user

      status = case subscription.status
               when "trialing" then "trial"
               when "active" then "active"
               when "past_due" then "past_due"
               when "canceled", "unpaid" then "cancelled"
               else "expired"
               end

      user.update!(
        subscription_status: status,
        trial_ends_at: subscription.trial_end.present? ? Time.at(subscription.trial_end) : nil
      )
    end

    def handle_subscription_deleted(subscription)
      user = find_user_from_customer(subscription.customer)
      return unless user

      user.update!(
        subscription_status: "cancelled",
        stripe_subscription_id: nil
      )
    end

    def handle_payment_succeeded(invoice)
      user = find_user_from_customer(invoice.customer)
      return unless user
      return unless invoice.subscription.present?

      # Payment succeeded, ensure subscription is active
      user.update!(subscription_status: "active") if user.past_due?
    end

    def handle_payment_failed(invoice)
      user = find_user_from_customer(invoice.customer)
      return unless user
      return unless invoice.subscription.present?

      user.update!(subscription_status: "past_due")

      # TODO: Send payment failed notification email
    end

    def handle_trial_ending(subscription)
      user = find_user_from_customer(subscription.customer)
      return unless user

      # TODO: Send trial ending notification email
      # TrialEndingMailer.notify(user).deliver_later
    end

    def find_user_from_session(session)
      if session.metadata&.user_id.present?
        User.find_by(id: session.metadata.user_id)
      elsif session.customer.present?
        User.find_by(stripe_customer_id: session.customer)
      end
    end

    def find_user_from_customer(customer_id)
      User.find_by(stripe_customer_id: customer_id)
    end
  end
end
