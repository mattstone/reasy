# frozen_string_literal: true

module Stripe
  class SubscriptionService
    def initialize(user)
      @user = user
      @customer_service = CustomerService.new(user)
    end

    def current_subscription
      return nil unless @user.stripe_subscription_id.present?

      @subscription ||= ::Stripe::Subscription.retrieve(@user.stripe_subscription_id)
    rescue ::Stripe::InvalidRequestError => e
      Rails.logger.error "Stripe subscription not found: #{e.message}"
      @user.update!(stripe_subscription_id: nil)
      nil
    end

    def create_subscription(price_id:, trial_days: nil)
      customer = @customer_service.find_or_create_customer

      subscription_params = {
        customer: customer.id,
        items: [{ price: price_id }],
        payment_behavior: "default_incomplete",
        expand: ["latest_invoice.payment_intent"]
      }

      # Add trial if specified
      if trial_days.present? && trial_days > 0
        subscription_params[:trial_period_days] = trial_days
      end

      subscription = ::Stripe::Subscription.create(subscription_params)

      @user.update!(
        stripe_subscription_id: subscription.id,
        subscription_status: subscription.status == "trialing" ? "trial" : "active",
        subscription_started_at: Time.current,
        trial_ends_at: subscription.trial_end.present? ? Time.at(subscription.trial_end) : nil
      )

      subscription
    end

    def cancel_subscription(at_period_end: true)
      return nil unless current_subscription

      subscription = ::Stripe::Subscription.update(
        @user.stripe_subscription_id,
        cancel_at_period_end: at_period_end
      )

      @user.update!(subscription_status: "cancelled") unless at_period_end

      subscription
    end

    def resume_subscription
      return nil unless current_subscription

      ::Stripe::Subscription.update(
        @user.stripe_subscription_id,
        cancel_at_period_end: false
      )
    end

    def change_plan(new_price_id:)
      return nil unless current_subscription

      subscription = current_subscription
      subscription_item_id = subscription.items.data.first.id

      ::Stripe::Subscription.update(
        @user.stripe_subscription_id,
        items: [{
          id: subscription_item_id,
          price: new_price_id
        }],
        proration_behavior: "create_prorations"
      )
    end

    def sync_status
      subscription = current_subscription
      return update_to_expired unless subscription

      new_status = case subscription.status
                   when "trialing"
                     "trial"
                   when "active"
                     "active"
                   when "past_due"
                     "past_due"
                   when "canceled", "unpaid"
                     "cancelled"
                   else
                     "expired"
                   end

      @user.update!(
        subscription_status: new_status,
        trial_ends_at: subscription.trial_end.present? ? Time.at(subscription.trial_end) : nil
      )
    end

    private

    def update_to_expired
      @user.update!(subscription_status: "expired", stripe_subscription_id: nil)
    end
  end
end
