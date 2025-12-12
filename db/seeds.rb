# frozen_string_literal: true

# This file creates seed data for testing and development.
# Run with: bin/rails db:seed

puts "Seeding database..."

# Clear existing seed users (for re-seeding)
test_emails = %w[
  admin@reasy.com.au
  buyer@reasy.com.au
  seller@reasy.com.au
  provider@reasy.com.au
  both@reasy.com.au
]

# Clean up associated records first, then users
test_user_ids = User.unscoped.where(email: test_emails).pluck(:id)
if test_user_ids.any?
  BuyerProfile.unscoped.where(user_id: test_user_ids).delete_all
  SellerProfile.unscoped.where(user_id: test_user_ids).delete_all
  ServiceProviderProfile.unscoped.where(user_id: test_user_ids).delete_all
  Property.unscoped.where(user_id: test_user_ids).delete_all
  User.unscoped.where(id: test_user_ids).delete_all
end

# ============================================
# Admin User
# ============================================
admin = User.create!(
  email: "admin@reasy.com.au",
  password: "password123",
  password_confirmation: "password123",
  name: "Admin User",
  roles: %w[admin buyer seller],
  kyc_status: "verified",
  kyc_verified_at: Time.current,
  subscription_status: "active",
  subscription_started_at: 1.year.ago,
  trial_ends_at: nil,
  terms_accepted_at: Time.current,
  privacy_policy_accepted_at: Time.current,
  onboarding_completed_at: Time.current,
  confirmed_at: Time.current
)
puts "✓ Created admin user: #{admin.email}"

# ============================================
# Buyer User
# ============================================
buyer = User.create!(
  email: "buyer@reasy.com.au",
  password: "password123",
  password_confirmation: "password123",
  name: "Sarah Buyer",
  roles: %w[buyer],
  kyc_status: "verified",
  kyc_verified_at: Time.current,
  subscription_status: "active",
  subscription_started_at: 1.month.ago,
  trial_ends_at: nil,
  terms_accepted_at: Time.current,
  privacy_policy_accepted_at: Time.current,
  onboarding_completed_at: Time.current,
  confirmed_at: Time.current
)

# Create buyer profile
buyer.create_buyer_profile!(
  finance_status: "pre_approved",
  budget_max_cents: 1_200_000_00,
  budget_min_cents: 800_000_00,
  search_areas: ["Sydney", "Northern Beaches"],
  property_types: %w[house townhouse],
  bedrooms_min: 3,
  bathrooms_min: 2
)
puts "✓ Created buyer user: #{buyer.email}"

# ============================================
# Seller User
# ============================================
seller = User.create!(
  email: "seller@reasy.com.au",
  password: "password123",
  password_confirmation: "password123",
  name: "Michael Seller",
  roles: %w[seller],
  kyc_status: "verified",
  kyc_verified_at: Time.current,
  subscription_status: "active",
  subscription_started_at: 2.months.ago,
  trial_ends_at: nil,
  terms_accepted_at: Time.current,
  privacy_policy_accepted_at: Time.current,
  onboarding_completed_at: Time.current,
  confirmed_at: Time.current
)

# Create seller profile
seller.create_seller_profile!(
  preferred_contact_method: "platform",
  preferred_settlement_period: "standard"
)
puts "✓ Created seller user: #{seller.email}"

# ============================================
# Service Provider User
# ============================================
provider = User.create!(
  email: "provider@reasy.com.au",
  password: "password123",
  password_confirmation: "password123",
  name: "Legal Eagle Conveyancing",
  roles: %w[service_provider],
  kyc_status: "verified",
  kyc_verified_at: Time.current,
  subscription_status: "active",
  subscription_started_at: 3.months.ago,
  trial_ends_at: nil,
  terms_accepted_at: Time.current,
  privacy_policy_accepted_at: Time.current,
  onboarding_completed_at: Time.current,
  confirmed_at: Time.current
)

# Create service provider profile
provider.create_service_provider_profile!(
  business_name: "Legal Eagle Conveyancing",
  service_type: "conveyancer",
  abn: "12345678901",
  description: "Professional conveyancing services with over 20 years of experience.",
  service_areas: ["Sydney", "NSW"],
  verification_status: "verified"
)
puts "✓ Created service provider user: #{provider.email}"

# ============================================
# Buyer & Seller User (both roles)
# ============================================
both = User.create!(
  email: "both@reasy.com.au",
  password: "password123",
  password_confirmation: "password123",
  name: "Jenny Both",
  roles: %w[buyer seller],
  kyc_status: "verified",
  kyc_verified_at: Time.current,
  subscription_status: "trial",
  trial_ends_at: 7.days.from_now,
  terms_accepted_at: Time.current,
  privacy_policy_accepted_at: Time.current,
  onboarding_completed_at: Time.current,
  confirmed_at: Time.current
)

both.create_buyer_profile!(
  finance_status: "exploring",
  budget_max_cents: 2_000_000_00,
  budget_min_cents: 1_500_000_00,
  search_areas: ["Melbourne", "Bayside"],
  property_types: %w[apartment unit],
  bedrooms_min: 2,
  bathrooms_min: 1
)

both.create_seller_profile!(
  preferred_contact_method: "platform",
  preferred_settlement_period: "flexible"
)
puts "✓ Created buyer+seller user: #{both.email}"

# ============================================
# Create sample property for seller
# ============================================
if seller.properties.empty? && defined?(Property)
  property = Property.create!(
    user: seller,
    headline: "Beautiful Family Home in Mosman",
    description: "A stunning 4-bedroom family home with harbour views, modern kitchen, and landscaped gardens. Walking distance to schools and shops.",
    street_address: "42 Harbour View Road",
    suburb: "Mosman",
    state: "NSW",
    postcode: "2088",
    country: "Australia",
    property_type: "house",
    bedrooms: 4,
    bathrooms: 3,
    parking_spaces: 2,
    land_size_sqm: 650,
    building_size_sqm: 320,
    price_cents: 3_500_000_00,
    price_display: "$3.5M",
    listing_intent: "want_to_sell",
    status: "active",
    published_at: 1.week.ago,
    features: ["Pool", "Harbour Views", "Ducted Air", "Solar Panels"]
  )
  puts "✓ Created sample property: #{property.headline}"
end

# ============================================
# Create legal documents
# ============================================
if defined?(LegalDocument) && LegalDocument.count.zero?
  terms = LegalDocument.create!(
    title: "Terms and Conditions",
    document_type: "terms_and_conditions",
    content: "These Terms and Conditions govern your use of Reasy...",
    version: "1.0",
    published_at: 1.month.ago,
    is_draft: false,
    is_current: true
  )
  puts "✓ Created Terms and Conditions"

  privacy = LegalDocument.create!(
    title: "Privacy Policy",
    document_type: "privacy_policy",
    content: "This Privacy Policy describes how Reasy collects, uses, and protects your personal information...",
    version: "1.0",
    published_at: 1.month.ago,
    is_draft: false,
    is_current: true
  )
  puts "✓ Created Privacy Policy"
end

puts ""
puts "=" * 50
puts "Seed data created successfully!"
puts "=" * 50
puts ""
puts "Test Users:"
puts "-" * 50
puts "Admin:            admin@reasy.com.au / password123"
puts "Buyer:            buyer@reasy.com.au / password123"
puts "Seller:           seller@reasy.com.au / password123"
puts "Service Provider: provider@reasy.com.au / password123"
puts "Buyer+Seller:     both@reasy.com.au / password123"
puts "-" * 50
puts ""
