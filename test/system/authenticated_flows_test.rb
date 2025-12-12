# frozen_string_literal: true

require "application_system_test_case"

# Comprehensive browser tests for all authenticated user flows.
# These tests verify that views render without errors for all user types.
#
# CRITICAL: These tests should be run after ANY view changes to catch:
# - Method calls on User model that don't exist
# - Wrong attribute names in views
# - Pundit authorization issues
# - Rails callback errors
#
# Run with: PARALLEL_WORKERS=1 bin/rails test test/system/authenticated_flows_test.rb
class AuthenticatedFlowsTest < ApplicationSystemTestCase
  # ============================================================================
  # SETUP
  # ============================================================================

  setup do
    @admin = User.find_by(email: "admin@reasy.com.au")
    @buyer = User.find_by(email: "buyer@reasy.com.au")
    @seller = User.find_by(email: "seller@reasy.com.au")
    @provider = User.find_by(email: "provider@reasy.com.au")
    @both = User.find_by(email: "both@reasy.com.au")
  end

  # Helper to login a user via the login form
  # Waits for dashboard to load after login
  def login_as(email, password = "password123")
    visit new_user_session_path
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Log in"
    # Wait for dashboard to fully load - use sidebar which is unique to dashboard
    assert_selector ".dashboard-sidebar"
  end

  # ============================================================================
  # DASHBOARD TESTS - All User Types
  # ============================================================================

  test "admin user can access dashboard without errors" do
    skip "Run db:seed first" unless @admin

    login_as("admin@reasy.com.au")

    # Verify dashboard loaded successfully
    assert_text "Welcome back"
    assert_selector ".dashboard-layout"
    assert_selector ".dashboard-sidebar"
    assert_selector ".dashboard-main"
  end

  test "buyer user can access dashboard without errors" do
    skip "Run db:seed first" unless @buyer

    login_as("buyer@reasy.com.au")

    assert_text "Welcome back"
    assert_selector ".dashboard-layout"
  end

  test "seller user can access dashboard without errors" do
    skip "Run db:seed first" unless @seller

    login_as("seller@reasy.com.au")

    assert_text "Welcome back"
    assert_selector ".dashboard-layout"
  end

  test "provider user can access dashboard without errors" do
    skip "Run db:seed first" unless @provider

    login_as("provider@reasy.com.au")

    assert_text "Welcome back"
    assert_selector ".dashboard-layout"
  end

  test "both roles user can access dashboard without errors" do
    skip "Run db:seed first" unless @both

    login_as("both@reasy.com.au")

    assert_text "Welcome back"
    assert_selector ".dashboard-layout"
  end

  # ============================================================================
  # ROLE-SPECIFIC CONTENT TESTS
  # ============================================================================

  test "buyer sees buyer-specific content on dashboard" do
    skip "Run db:seed first" unless @buyer

    login_as("buyer@reasy.com.au")

    # Buyers should see property-related cards
    assert_text "Property matches"
    assert_text "Saved properties"
  end

  test "seller sees seller-specific content on dashboard" do
    skip "Run db:seed first" unless @seller

    login_as("seller@reasy.com.au")

    # Sellers should see listing-related cards
    assert_text "Your listings"
    assert_text "Enquiries"
  end

  test "both roles user sees buyer and seller content" do
    skip "Run db:seed first" unless @both

    login_as("both@reasy.com.au")

    # Wait for dashboard to load
    assert_text "Welcome back"

    # Should see both buyer and seller content
    assert_text "Property matches"
    assert_text "Your listings"
  end

  # ============================================================================
  # ADMIN TESTS
  # ============================================================================

  test "admin can access admin dashboard" do
    skip "Run db:seed first" unless @admin

    login_as("admin@reasy.com.au")
    assert_text "Welcome back"

    visit admin_root_path
    assert_text "Admin Dashboard"
    assert_text "Total Users"
  end

  test "non-admin cannot access admin dashboard" do
    skip "Run db:seed first" unless @buyer

    login_as("buyer@reasy.com.au")
    assert_text "Welcome back"

    visit admin_root_path
    # Should be redirected away from admin
    assert_no_text "Admin Dashboard"
  end

  # ============================================================================
  # NAVIGATION TESTS
  # ============================================================================

  test "dashboard sidebar renders correctly" do
    skip "Run db:seed first" unless @admin

    login_as("admin@reasy.com.au")

    # Wait for dashboard to fully load first
    assert_text "Welcome back"

    assert_selector ".dashboard-sidebar"
    assert_link "Dashboard"
    assert_link "Messages"
    assert_link "Settings"
    assert_button "Log out"
  end

  test "logout works from dashboard" do
    skip "Run db:seed first" unless @admin

    login_as("admin@reasy.com.au")
    assert_text "Welcome back"

    click_button "Log out"

    # Should be logged out and on a public page
    assert_no_text "Welcome back"
  end

  # ============================================================================
  # PUBLIC PAGES AFTER LOGIN
  # ============================================================================

  test "logged in user can view properties index" do
    skip "Run db:seed first" unless @buyer

    login_as("buyer@reasy.com.au")
    assert_text "Welcome back"

    visit properties_path
    # Should render without errors
    assert_selector "h1"
  end

  # ============================================================================
  # EDGE CASE TESTS
  # ============================================================================

  test "dashboard handles user display name gracefully" do
    skip "Run db:seed first" unless @admin

    login_as("admin@reasy.com.au")

    # Should display first name or fallback, not crash
    assert_text "Welcome back"
    # The greeting should contain either the name or "there"
    assert_selector "h1", text: /Welcome back,/
  end
end
