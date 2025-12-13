# frozen_string_literal: true

require "test_helper"

class UserPagesTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!
    @user = create(:user, :buyer, :seller, :onboarded, :with_terms_accepted, :subscribed,
                   email: "test_user_#{SecureRandom.hex(4)}@example.com")
    # Create buyer profile for the user
    @buyer_profile = create(:buyer_profile, user: @user)
    login_as(@user, scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  # ============================================================================
  # DASHBOARD TESTS
  # ============================================================================

  test "dashboard page loads successfully" do
    get dashboard_path
    assert_response :success
  end

  # ============================================================================
  # BUYER PROFILE TESTS
  # ============================================================================

  test "buyer profile show page loads successfully" do
    get buyer_profile_path
    assert_response :success
  end

  # ============================================================================
  # AI CONVERSATIONS TESTS
  # ============================================================================

  test "ai conversations index page loads successfully" do
    get ai_conversations_path
    assert_response :success
  end

  # ============================================================================
  # CO-USERS TESTS
  # ============================================================================

  test "co-users index page loads successfully" do
    get co_users_path
    assert_response :success
  end

  test "co-users invitations page loads successfully" do
    get invitations_co_users_path
    assert_response :success
  end

  # ============================================================================
  # SETTINGS TESTS
  # ============================================================================

  test "settings page (edit registration) loads successfully" do
    get edit_user_registration_path
    assert_response :success
  end

  # ============================================================================
  # NOTIFICATIONS TESTS
  # ============================================================================

  test "notifications index page loads successfully" do
    get notifications_path
    assert_response :success
  end

  # ============================================================================
  # CONVERSATIONS TESTS
  # ============================================================================

  test "conversations index page loads successfully" do
    get conversations_path
    assert_response :success
  end

  # ============================================================================
  # ENTITIES TESTS
  # ============================================================================

  test "entities index page loads successfully" do
    get entities_path
    assert_response :success
  end

  # ============================================================================
  # REVIEWS TESTS
  # ============================================================================

  test "reviews index page loads successfully" do
    get reviews_path
    assert_response :success
  end

  # ============================================================================
  # SAVED PROPERTIES TESTS
  # ============================================================================

  test "saved properties page loads successfully" do
    get buyer_saved_properties_path
    assert_response :success
  end

  # ============================================================================
  # SAVED SEARCHES TESTS
  # ============================================================================

  test "saved searches page loads successfully" do
    get buyer_saved_searches_path
    assert_response :success
  end

  # ============================================================================
  # SELLER PROFILE TESTS
  # ============================================================================

  test "seller profile show page loads successfully" do
    # Create seller profile
    create(:seller_profile, user: @user)
    get seller_profile_path
    assert_response :success
  end

  # ============================================================================
  # SELLER PROPERTIES TESTS
  # ============================================================================

  test "seller properties index page loads successfully" do
    get seller_properties_path
    assert_response :success
  end

  # ============================================================================
  # KYC VERIFICATION TESTS
  # ============================================================================

  test "kyc verification page loads successfully" do
    get kyc_verification_path
    assert_response :success
  end
end
