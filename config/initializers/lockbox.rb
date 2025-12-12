# frozen_string_literal: true

# Lockbox configuration for encrypting sensitive data
# Generate a key with: Lockbox.generate_key
# Or: ruby -e "require 'securerandom'; puts SecureRandom.hex(32)"

# Allow asset precompilation without keys (SECRET_KEY_BASE_DUMMY is set during Docker build)
if ENV["SECRET_KEY_BASE_DUMMY"].present?
  Lockbox.master_key = "0" * 64
  BlindIndex.master_key = "0" * 64
else
  # Try ENV first, then credentials, then dev fallback
  Lockbox.master_key = ENV["LOCKBOX_MASTER_KEY"].presence ||
                       Rails.application.credentials.dig(:lockbox_master_key) ||
                       (Rails.env.local? ? "0" * 64 : nil)

  BlindIndex.master_key = ENV["BLIND_INDEX_MASTER_KEY"].presence ||
                          Rails.application.credentials.dig(:blind_index_master_key) ||
                          (Rails.env.local? ? "0" * 64 : nil)

  # Validate in production
  if Rails.env.production?
    raise "LOCKBOX_MASTER_KEY not configured" unless Lockbox.master_key.present?
    raise "BLIND_INDEX_MASTER_KEY not configured" unless BlindIndex.master_key.present?
  end
end
