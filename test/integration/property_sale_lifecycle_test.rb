# frozen_string_literal: true

require "test_helper"

class PropertySaleLifecycleTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  # Modern browser User-Agent to pass allow_browser :modern check
  CHROME_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

  setup do
    Warden.test_mode!
    setup_users_and_profiles
    # Set modern browser User-Agent for all requests
    @default_headers = { "HTTP_USER_AGENT" => CHROME_USER_AGENT }
  end

  teardown do
    Warden.test_reset!
  end

  # Override get/post to include User-Agent header
  def get(path, **options)
    options[:headers] = @default_headers.merge(options[:headers] || {})
    super
  end

  def post(path, **options)
    options[:headers] = @default_headers.merge(options[:headers] || {})
    super
  end

  def delete(path, **options)
    options[:headers] = @default_headers.merge(options[:headers] || {})
    super
  end

  # ============================================================================
  # HAPPY PATH: COMPLETE SALE LIFECYCLE
  # ============================================================================

  test "complete property sale from listing to settlement and reviews" do
    # 1. Seller lists property
    login_as(@seller, scope: :user)
    get seller_properties_path
    assert_response :success

    # Seller can view their properties page
    get new_seller_property_path
    assert_response :success

    # 2. Create a property directly (simulating wizard completion)
    property = create(:property, :active, :with_pricing, :with_full_details,
                      user: @seller, entity: @seller_entity)
    assert property.active?

    # 3. Buyer discovers and views property
    logout
    login_as(@buyer, scope: :user)

    # Browse properties
    get properties_path
    assert_response :success

    # View specific property
    get property_path(property)
    assert_response :success

    # 4. Buyer saves property to favorites
    post love_property_path(property)
    assert_response :redirect
    assert PropertyLove.exists?(user: @buyer, property: property)

    # 5. Buyer makes offer (direct creation since routes aren't defined)
    offer = Offer.create!(
      property: property,
      buyer: @buyer,
      buyer_entity: @buyer_entity,
      amount_cents: 850_000_00,
      deposit_cents: 85_000_00,
      finance_type: "pre_approved",
      settlement_days: 42,
      subject_to_finance: true,
      subject_to_building_inspection: true,
      status: "submitted",
      submitted_at: Time.current
    )
    assert offer.submitted?

    # 6. Seller views and accepts offer
    logout
    login_as(@seller, scope: :user)

    get seller_property_offers_path(property)
    assert_response :success

    get seller_property_offer_path(property, offer)
    assert_response :success
    offer.reload
    assert offer.viewed?

    # Accept the offer
    post accept_seller_property_offer_path(property, offer)
    assert_response :redirect
    offer.reload
    assert offer.accepted?

    # 7. Transaction should be created
    transaction = offer.property_transaction
    assert transaction.present?
    assert transaction.pending?
    assert_equal @seller, transaction.seller
    assert_equal @buyer, transaction.buyer

    # 8. Progress transaction through lifecycle
    # Exchange contracts
    transaction.exchange!
    assert transaction.exchanged?

    # Start cooling-off period
    transaction.start_cooling_off!
    assert transaction.in_cooling_off?

    # Go unconditional (after cooling-off)
    transaction.update!(cooling_off_ends_at: 1.day.ago) # Simulate cooling-off ended
    transaction.go_unconditional!
    assert transaction.unconditional?

    # Satisfy conditions and start settling
    transaction.approve_finance!
    transaction.pass_building_inspection!
    transaction.start_settling!
    assert transaction.settling?

    # Complete settlement
    transaction.settle!
    assert transaction.settled?
    property.reload
    assert property.sold?

    # 9. Both parties can leave reviews
    # Buyer reviews seller
    buyer_review = create(:review, :for_seller, :published,
                          reviewer: @buyer,
                          reviewee: @seller,
                          overall_rating: 5,
                          body: "Excellent seller, very responsive and honest about the property.")
    assert buyer_review.published?

    # Seller reviews buyer
    logout
    login_as(@seller, scope: :user)
    seller_review = create(:review, :for_buyer, :published,
                           reviewer: @seller,
                           reviewee: @buyer,
                           overall_rating: 5,
                           body: "Great buyer, smooth transaction from start to finish.")
    assert seller_review.published?

    # Verify reviews are accessible
    get reviews_path
    assert_response :success
  end

  # ============================================================================
  # COUNTER-OFFER FLOW
  # ============================================================================

  test "offer counter negotiation cycle" do
    property = create(:property, :active, :with_pricing, user: @seller, entity: @seller_entity)

    # Buyer submits offer (buyer_entity required for counter-offers)
    offer = create(:offer, :submitted, property: property, buyer: @buyer, buyer_entity: @buyer_entity, amount_cents: 800_000_00)

    # Seller counters
    login_as(@seller, scope: :user)
    get seller_property_offer_path(property, offer)
    offer.reload
    assert offer.viewed?

    post counter_seller_property_offer_path(property, offer), params: {
      counter_amount: 850_000
    }
    assert_response :redirect

    offer.reload
    assert offer.countered?

    # Counter-offer should exist
    counter_offer = offer.counter_offers.first
    assert counter_offer.present?
    assert counter_offer.submitted?
    assert_equal 850_000_00, counter_offer.amount_cents
  end

  # ============================================================================
  # REJECTED OFFER
  # ============================================================================

  test "seller rejects offer" do
    property = create(:property, :active, :with_pricing, user: @seller, entity: @seller_entity)
    offer = create(:offer, :submitted, property: property, buyer: @buyer)

    login_as(@seller, scope: :user)
    get seller_property_offer_path(property, offer)
    offer.reload

    post reject_seller_property_offer_path(property, offer)
    assert_response :redirect

    offer.reload
    assert offer.rejected?

    # Property should still be active (can receive new offers)
    property.reload
    assert property.active?
  end

  # ============================================================================
  # BUYER WITHDRAWS OFFER
  # ============================================================================

  test "buyer withdraws offer before acceptance" do
    property = create(:property, :active, :with_pricing, user: @seller, entity: @seller_entity)
    offer = create(:offer, :submitted, property: property, buyer: @buyer, buyer_entity: @buyer_entity)

    # Buyer withdraws
    result = offer.withdraw!
    assert result
    assert offer.withdrawn?

    # Property remains available
    property.reload
    assert property.active?
  end

  # ============================================================================
  # TRANSACTION FALLS THROUGH
  # ============================================================================

  test "transaction cancelled during cooling off period" do
    property = create(:property, :active, :with_pricing, user: @seller, entity: @seller_entity)
    offer = create(:offer, :submitted, property: property, buyer: @buyer, buyer_entity: @buyer_entity)

    # Accept offer and progress to cooling-off
    offer.accept!
    transaction = offer.property_transaction
    transaction.exchange!
    transaction.start_cooling_off!

    assert transaction.in_cooling_off?
    assert transaction.can_rescind?

    # Buyer exercises cooling-off rights
    transaction.rescind!
    transaction.reload
    assert transaction.fallen_through?

    # Property returns to market
    property.reload
    assert property.active?
  end

  # ============================================================================
  # SERVICE PROVIDER ENGAGEMENT
  # ============================================================================

  test "seller engages service provider during sale" do
    # Ensure service provider has a verified profile (required by controller)
    @service_provider_profile ||= create(:service_provider_profile, :verified, user: @service_provider)

    login_as(@seller, scope: :user)

    # Service providers directory is accessible
    get service_providers_path
    assert_response :success

    # Can view individual service provider (using profile ID, not user)
    get service_provider_path(@service_provider_profile)
    assert_response :success

    # Can view conversations
    get conversations_path
    assert_response :success
  end

  # ============================================================================
  # REVIEW SYSTEM WITH 48-HOUR HOLD
  # ============================================================================

  test "negative review held for 48 hours" do
    # Complete a transaction first
    property = create(:property, :active, :with_pricing, user: @seller, entity: @seller_entity)
    offer = create(:offer, :submitted, property: property, buyer: @buyer, buyer_entity: @buyer_entity)
    offer.accept!
    transaction = offer.property_transaction
    transaction.exchange!
    transaction.start_cooling_off!
    transaction.update!(cooling_off_ends_at: 1.day.ago)
    transaction.go_unconditional!
    transaction.settle!

    # Buyer leaves negative review (2 stars)
    negative_review = Review.create!(
      reviewer: @buyer,
      reviewee: @seller,
      reviewee_role: "seller",
      overall_rating: 2,
      title: "Disappointing experience",
      body: "The property had several undisclosed issues that only became apparent after purchase."
    )

    # Review should be automatically held
    assert negative_review.held?
    assert negative_review.hold_until.present?
    assert negative_review.hold_until > Time.current

    # Review not visible to seller yet (held status means not published)
    assert_not negative_review.published?

    # Admin can publish after review
    negative_review.publish! if negative_review.hold_expired?
    # Since hold hasn't expired, it should still be held
    assert negative_review.held?

    # Simulate hold expiring
    negative_review.update!(hold_until: 1.hour.ago)
    assert negative_review.hold_expired?
    assert negative_review.can_publish?

    negative_review.publish!
    assert negative_review.published?
  end

  test "positive review published immediately" do
    positive_review = Review.create!(
      reviewer: @buyer,
      reviewee: @seller,
      reviewee_role: "seller",
      overall_rating: 5,
      title: "Fantastic experience",
      body: "Everything went smoothly, seller was very helpful and honest throughout."
    )

    # Positive review should be published immediately
    assert positive_review.published?
    assert_not positive_review.held?
  end

  # ============================================================================
  # SMOKE TESTS: VIEW RENDERING
  # ============================================================================

  test "seller views render without errors" do
    login_as(@seller, scope: :user)

    # Verify user is properly set up
    assert @seller.onboarding_completed_at.present?, "User should be onboarded"
    assert @seller.terms_accepted_at.present?, "User should have terms accepted"
    assert_not @seller.needs_to_accept_legal_documents?, "User should not need to accept legal documents"

    get seller_properties_path
    assert_response :success, "seller_properties_path: #{response.status}, redirected to: #{response.location}"

    get new_seller_property_path
    assert_response :success, "new_seller_property_path: #{response.status}, redirected to: #{response.location}"

    get seller_profile_path
    assert_response :success, "seller_profile_path: #{response.status}, redirected to: #{response.location}"
  end

  test "buyer views render without errors" do
    login_as(@buyer, scope: :user)

    get buyer_profile_path
    assert_response :success

    get buyer_saved_properties_path
    assert_response :success

    get buyer_saved_searches_path
    assert_response :success
  end

  test "public property views render without errors" do
    property = create(:property, :active, :with_pricing, :with_full_details, user: @seller)

    get properties_path
    assert_response :success

    get property_path(property)
    assert_response :success

    get property_search_path
    assert_response :success
  end

  test "transaction views render without errors" do
    # Create a settled transaction
    property = create(:property, :active, :with_pricing, user: @seller, entity: @seller_entity)
    offer = create(:offer, :submitted, property: property, buyer: @buyer, buyer_entity: @buyer_entity)
    offer.accept!
    transaction = offer.property_transaction

    login_as(@buyer, scope: :user)

    # Note: Transactions controller may need routes for user-facing views
    # This tests the admin transaction views are accessible
    logout
    login_as(@admin, scope: :user)

    get admin_transactions_path
    assert_response :success

    get admin_transaction_path(transaction)
    assert_response :success
  end

  test "service provider views render without errors" do
    # Ensure service provider has a verified profile (required by controller)
    @service_provider_profile ||= create(:service_provider_profile, :verified, user: @service_provider)

    get service_providers_path
    assert_response :success

    get service_provider_path(@service_provider_profile)
    assert_response :success
  end

  test "review views render without errors" do
    login_as(@buyer, scope: :user)

    get reviews_path
    assert_response :success
  end

  # ============================================================================
  # AUTHORIZATION TESTS
  # ============================================================================

  test "seller cannot accept offer on another sellers property" do
    other_seller = create(:user, :seller, :onboarded, :with_terms_accepted, :subscribed)
    create(:legal_document_acceptance, user: other_seller, legal_document: @terms)
    create(:legal_document_acceptance, user: other_seller, legal_document: @privacy)
    other_seller_profile = create(:seller_profile, user: other_seller)
    other_property = create(:property, :active, :with_pricing, user: other_seller)
    offer = create(:offer, :submitted, property: other_property, buyer: @buyer)

    login_as(@seller, scope: :user)

    # Should not be able to access another seller's offers (returns 404 as property not in current_user.properties)
    get seller_property_offers_path(other_property)
    assert_response :not_found
  end

  test "buyer cannot access seller offer management" do
    property = create(:property, :active, :with_pricing, user: @seller, entity: @seller_entity)
    offer = create(:offer, :submitted, property: property, buyer: @buyer)

    login_as(@buyer, scope: :user)

    # Buyer should not be able to access seller's offers (returns 404 as property not in current_user.properties)
    get seller_property_offers_path(property)
    assert_response :not_found
  end

  private

  def setup_users_and_profiles
    # Ensure no conflicting current legal documents exist
    LegalDocument.update_all(is_current: false)

    # Create published legal documents (required for user authentication flow)
    @terms = create(:legal_document, :terms, :published)
    @privacy = create(:legal_document, :privacy, :published)

    # Create seller
    @seller = create(:user, :seller, :onboarded, :with_terms_accepted, :subscribed,
                     email: "seller_#{SecureRandom.hex(4)}@example.com")
    @seller_profile = create(:seller_profile, user: @seller)
    @seller_entity = create(:entity, :individual, user: @seller)
    # Accept legal documents
    create(:legal_document_acceptance, user: @seller, legal_document: @terms)
    create(:legal_document_acceptance, user: @seller, legal_document: @privacy)

    # Create buyer
    @buyer = create(:user, :buyer, :onboarded, :with_terms_accepted, :subscribed,
                    email: "buyer_#{SecureRandom.hex(4)}@example.com")
    @buyer_profile = create(:buyer_profile, user: @buyer)
    @buyer_entity = create(:entity, :individual, user: @buyer)
    # Accept legal documents
    create(:legal_document_acceptance, user: @buyer, legal_document: @terms)
    create(:legal_document_acceptance, user: @buyer, legal_document: @privacy)

    # Create service provider
    @service_provider = create(:user, :service_provider, :onboarded, :with_terms_accepted, :subscribed,
                               email: "provider_#{SecureRandom.hex(4)}@example.com")
    # Accept legal documents
    create(:legal_document_acceptance, user: @service_provider, legal_document: @terms)
    create(:legal_document_acceptance, user: @service_provider, legal_document: @privacy)

    # Create admin for admin-only tests
    @admin = create(:user, :admin, :onboarded, :with_terms_accepted,
                    email: "admin_#{SecureRandom.hex(4)}@example.com")
    # Accept legal documents
    create(:legal_document_acceptance, user: @admin, legal_document: @terms)
    create(:legal_document_acceptance, user: @admin, legal_document: @privacy)
  end
end
