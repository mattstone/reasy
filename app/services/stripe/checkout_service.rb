# frozen_string_literal: true

module Stripe
  class CheckoutService
    def initialize(user)
      @user = user
      @customer_service = CustomerService.new(user)
    end

    def create_checkout_session(price_id:, success_url:, cancel_url:, mode: "subscription")
      customer = @customer_service.find_or_create_customer

      session_params = {
        customer: customer.id,
        mode: mode,
        success_url: success_url,
        cancel_url: cancel_url,
        metadata: {
          user_id: @user.id
        }
      }

      if mode == "subscription"
        session_params[:line_items] = [{ price: price_id, quantity: 1 }]

        # 24-hour free trial for new subscriptions
        if @user.trial? || @user.subscription_status == "expired"
          session_params[:subscription_data] = {
            trial_period_days: Rails.configuration.stripe.trial_period_days
          }
        end
      else
        # One-time payment
        session_params[:line_items] = [{ price: price_id, quantity: 1 }]
      end

      ::Stripe::Checkout::Session.create(session_params)
    end

    def create_buyer_checkout(success_url:, cancel_url:, yearly: false)
      price_id = yearly ?
        Rails.configuration.stripe.buyer_yearly_price_id :
        Rails.configuration.stripe.buyer_monthly_price_id

      create_checkout_session(
        price_id: price_id,
        success_url: success_url,
        cancel_url: cancel_url
      )
    end

    def create_seller_checkout(success_url:, cancel_url:, yearly: false)
      price_id = yearly ?
        Rails.configuration.stripe.seller_yearly_price_id :
        Rails.configuration.stripe.seller_monthly_price_id

      create_checkout_session(
        price_id: price_id,
        success_url: success_url,
        cancel_url: cancel_url
      )
    end
  end
end
