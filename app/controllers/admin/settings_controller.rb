# frozen_string_literal: true

module Admin
  class SettingsController < Admin::BaseController
    def show
      @settings = {
        platform_name: "Reasy",
        support_email: "support@reasy.com.au",
        max_property_images: 20,
        trial_period_hours: 24,
        review_moderation_hours: 48,
        cooling_off_period_days: 5
      }
    end

    def update
      # In a real app, this would update a Settings model or ENV vars
      redirect_to admin_settings_path, notice: "Settings updated successfully."
    end

    def integrations
      @integrations = {
        stripe: {
          enabled: ENV["STRIPE_SECRET_KEY"].present?,
          mode: ENV["STRIPE_SECRET_KEY"]&.start_with?("sk_live") ? "live" : "test"
        },
        anthropic: {
          enabled: ENV["ANTHROPIC_API_KEY"].present?
        },
        google_maps: {
          enabled: ENV["GOOGLE_MAPS_API_KEY"].present?
        }
      }
    end

    def update_integrations
      redirect_to integrations_admin_settings_path, notice: "Integration settings updated."
    end
  end
end
