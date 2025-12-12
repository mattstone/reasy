# frozen_string_literal: true

module Stripe
  class CustomerService
    def initialize(user)
      @user = user
    end

    def find_or_create_customer
      return ::Stripe::Customer.retrieve(@user.stripe_customer_id) if @user.stripe_customer_id.present?

      customer = ::Stripe::Customer.create(
        email: @user.email,
        name: @user.full_name,
        metadata: {
          user_id: @user.id,
          roles: @user.active_roles.join(",")
        }
      )

      @user.update!(stripe_customer_id: customer.id)
      customer
    end

    def update_customer
      return nil unless @user.stripe_customer_id.present?

      ::Stripe::Customer.update(
        @user.stripe_customer_id,
        email: @user.email,
        name: @user.full_name,
        metadata: {
          user_id: @user.id,
          roles: @user.active_roles.join(",")
        }
      )
    end

    def customer
      return nil unless @user.stripe_customer_id.present?

      @customer ||= ::Stripe::Customer.retrieve(@user.stripe_customer_id)
    rescue ::Stripe::InvalidRequestError => e
      Rails.logger.error "Stripe customer not found: #{e.message}"
      @user.update!(stripe_customer_id: nil)
      nil
    end

    def billing_portal_session(return_url:)
      customer = find_or_create_customer
      ::Stripe::BillingPortal::Session.create(
        customer: customer.id,
        return_url: return_url
      )
    end
  end
end
