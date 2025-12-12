# frozen_string_literal: true

module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def create
      payload = request.body.read
      signature = request.headers["Stripe-Signature"]

      handler = ::Stripe::WebhookHandler.new(payload: payload, signature: signature)
      result = handler.process!

      if result[:error]
        render json: { error: result[:error] }, status: :bad_request
      else
        render json: { received: true, event_type: result[:event_type] }, status: :ok
      end
    end
  end
end
