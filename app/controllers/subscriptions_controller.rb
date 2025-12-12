# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def show
    @subscription_service = ::Stripe::SubscriptionService.new(current_user)
    @current_subscription = @subscription_service.current_subscription
  end

  def edit
    @subscription_service = ::Stripe::SubscriptionService.new(current_user)
    @current_subscription = @subscription_service.current_subscription
  end

  def update
    # Handled via Stripe Checkout
    redirect_to subscription_path
  end

  def checkout
    checkout_service = ::Stripe::CheckoutService.new(current_user)

    plan_type = params[:plan_type] || "buyer"
    yearly = params[:yearly] == "true"

    session = if plan_type == "seller"
                checkout_service.create_seller_checkout(
                  success_url: success_subscription_url,
                  cancel_url: cancel_subscription_url,
                  yearly: yearly
                )
              else
                checkout_service.create_buyer_checkout(
                  success_url: success_subscription_url,
                  cancel_url: cancel_subscription_url,
                  yearly: yearly
                )
              end

    redirect_to session.url, allow_other_host: true
  rescue ::Stripe::StripeError => e
    redirect_to subscription_path, alert: "Could not create checkout session: #{e.message}"
  end

  def success
    # Sync subscription status from Stripe
    ::Stripe::SubscriptionService.new(current_user).sync_status

    redirect_to dashboard_path, notice: "Subscription activated successfully!"
  end

  def cancel
    redirect_to subscription_path, notice: "Checkout cancelled."
  end

  def portal
    customer_service = ::Stripe::CustomerService.new(current_user)
    session = customer_service.billing_portal_session(return_url: subscription_url)

    redirect_to session.url, allow_other_host: true
  rescue ::Stripe::StripeError => e
    redirect_to subscription_path, alert: "Could not access billing portal: #{e.message}"
  end
end
