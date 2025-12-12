# frozen_string_literal: true

Rails.application.configure do
  config.stripe = ActiveSupport::OrderedOptions.new

  # Helper to fetch from ENV first, then credentials
  fetch_config = ->(env_key, cred_path) {
    ENV[env_key].presence || Rails.application.credentials.dig(*cred_path)
  }

  # Stripe API keys (ENV takes precedence, then credentials)
  config.stripe.secret_key = fetch_config.call("STRIPE_SECRET_KEY", [:stripe, :secret_key])
  config.stripe.publishable_key = fetch_config.call("STRIPE_PUBLISHABLE_KEY", [:stripe, :publishable_key])
  config.stripe.webhook_secret = fetch_config.call("STRIPE_WEBHOOK_SECRET", [:stripe, :webhook_secret])

  # Product/Price IDs
  config.stripe.buyer_monthly_price_id = fetch_config.call("STRIPE_BUYER_MONTHLY_PRICE_ID", [:stripe, :buyer_monthly_price_id])
  config.stripe.buyer_yearly_price_id = fetch_config.call("STRIPE_BUYER_YEARLY_PRICE_ID", [:stripe, :buyer_yearly_price_id])
  config.stripe.seller_monthly_price_id = fetch_config.call("STRIPE_SELLER_MONTHLY_PRICE_ID", [:stripe, :seller_monthly_price_id])
  config.stripe.seller_yearly_price_id = fetch_config.call("STRIPE_SELLER_YEARLY_PRICE_ID", [:stripe, :seller_yearly_price_id])

  # Trial period
  config.stripe.trial_period_days = 1 # 24-hour free trial
end

# Configure Stripe gem (skip during asset precompilation)
unless ENV["SECRET_KEY_BASE_DUMMY"].present?
  Stripe.api_key = Rails.configuration.stripe.secret_key if Rails.configuration.stripe.secret_key.present?
end
