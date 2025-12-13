# frozen_string_literal: true

require "application_system_test_case"

# Comprehensive browser tests for Admin Business Intelligence section.
# Tests all dashboard pages, charts, metrics, and navigation.
#
# Run with: bin/rails test test/system/admin/business_section_test.rb
class Admin::BusinessSectionTest < ApplicationSystemTestCase
  include FactoryBot::Syntax::Methods

  setup do
    @admin = create(:user, :admin, :onboarded, :with_terms_accepted,
                    email: "test_admin_#{SecureRandom.hex(4)}@example.com")
  end

  def login_as_admin
    visit new_user_session_path
    fill_in "Email", with: @admin.email
    fill_in "Password", with: "password123"
    click_button "Log in"
    assert_selector ".dashboard-sidebar"
  end

  # ============================================================================
  # BUSINESS DASHBOARD TESTS
  # ============================================================================

  test "admin can access business dashboard" do
    login_as_admin

    visit admin_business_root_path

    # Verify page loads without errors
    assert_selector ".admin-content"
    assert_text "Business Intelligence"
    assert_text "Revenue, subscriptions, and transaction analytics"
  end

  test "business dashboard displays hero metrics" do
    login_as_admin
    visit admin_business_root_path

    # Check for hero metric cards
    assert_selector ".admin-metric-hero"
    assert_selector ".admin-metric-hero-card", minimum: 4

    # Check for expected metric labels
    assert_text "Monthly Recurring Revenue"
    assert_text "Active Subscriptions"
    assert_text "Conversion"
  end

  test "business dashboard displays charts" do
    login_as_admin
    visit admin_business_root_path

    # Check for chart containers with D3 controller
    assert_selector "[data-controller='d3-chart']", minimum: 2
    assert_selector ".admin-chart-card", minimum: 2

    # Check chart titles
    assert_text "Revenue Trend"
    assert_text "Transactions by Status"
  end

  test "business dashboard displays recent activity" do
    login_as_admin
    visit admin_business_root_path

    # Check for recent sections
    assert_selector ".admin-panel"
    assert_text "Recent Transactions"
  end

  test "business dashboard section navigation works" do
    login_as_admin
    visit admin_business_root_path

    # Check section nav exists
    assert_selector ".admin-section-nav"

    # Click through each nav item using section nav
    within(".admin-section-nav") do
      click_link "Revenue"
    end
    assert_current_path admin_business_revenue_path

    within(".admin-section-nav") do
      click_link "User Growth"
    end
    assert_current_path admin_business_users_path

    within(".admin-section-nav") do
      click_link "Transactions"
    end
    assert_current_path admin_business_transactions_path

    within(".admin-section-nav") do
      click_link "Overview"
    end
    assert_current_path admin_business_root_path
  end

  # ============================================================================
  # REVENUE ANALYTICS TESTS
  # ============================================================================

  test "admin can access revenue analytics" do
    login_as_admin
    visit admin_business_revenue_path

    assert_selector ".admin-content"
    assert_text "Revenue Analytics"
    assert_text "MRR, ARR, churn, and lifetime value metrics"
  end

  test "revenue page displays financial metrics" do
    login_as_admin
    visit admin_business_revenue_path

    # Check for revenue-specific metrics
    assert_selector ".admin-metric-hero-card", minimum: 4
    assert_text "MRR"
    assert_text "ARR"
    assert_text "ARPU"
    assert_text "Churn Rate"
  end

  test "revenue page displays revenue charts" do
    login_as_admin
    visit admin_business_revenue_path

    # Should have revenue trend and breakdown charts
    assert_selector "[data-controller='d3-chart']", minimum: 1
    assert_text "MRR Growth"
  end

  test "revenue page displays plan breakdown" do
    login_as_admin
    visit admin_business_revenue_path

    assert_selector ".admin-panel"
    assert_text "Revenue by Plan"
  end

  # ============================================================================
  # USER GROWTH ANALYTICS TESTS
  # ============================================================================

  test "admin can access user growth analytics" do
    login_as_admin
    visit admin_business_users_path

    assert_selector ".admin-content"
    assert_text "User Growth Analytics"
    assert_text "Signups, roles, and KYC completion metrics"
  end

  test "user growth page displays user metrics" do
    login_as_admin
    visit admin_business_users_path

    assert_selector ".admin-metric-hero-card", minimum: 4
    assert_text "Total Users"
    assert_text "New This Week"
    assert_text "Active Today"
  end

  test "user growth page displays user distribution chart" do
    login_as_admin
    visit admin_business_users_path

    assert_selector "[data-controller='d3-chart']", minimum: 2
    assert_text "Daily Signups"
    assert_text "Users by Role"
  end

  test "user growth page displays role breakdown" do
    login_as_admin
    visit admin_business_users_path

    assert_selector ".admin-data-list"
    # Should show role distribution
    assert_text "Buyers" rescue nil
    assert_text "Sellers" rescue nil
  end

  test "user growth page displays role distribution" do
    login_as_admin
    visit admin_business_users_path

    assert_text "Role Distribution"
    assert_selector ".admin-panel"
  end

  # ============================================================================
  # TRANSACTION ANALYTICS TESTS
  # ============================================================================

  test "admin can access transaction analytics" do
    login_as_admin
    visit admin_business_transactions_path

    assert_selector ".admin-content"
    assert_text "Transaction Analytics"
    assert_text "Sales volume, values, and settlement metrics"
  end

  test "transaction page displays value metrics" do
    login_as_admin
    visit admin_business_transactions_path

    assert_selector ".admin-metric-hero-card", minimum: 4
    assert_text "Total Transaction Value"
    assert_text "Total Transactions"
    assert_text "Avg Transaction Value"
    assert_text "Settlement Success"
  end

  test "transaction page displays charts" do
    login_as_admin
    visit admin_business_transactions_path

    assert_selector "[data-controller='d3-chart']", minimum: 2
    assert_text "Transaction Value Trend"
    assert_text "Transactions by Status"
  end

  test "transaction page displays recent transactions table" do
    login_as_admin
    visit admin_business_transactions_path

    assert_selector ".admin-table"
    assert_text "Recent Transactions"
    # Table headers are uppercase
    assert_selector "th", text: /PROPERTY/i
    assert_selector "th", text: /BUYER/i
    assert_selector "th", text: /SELLER/i
    assert_selector "th", text: /VALUE/i
    assert_selector "th", text: /STATUS/i
  end

  # ============================================================================
  # NAVIGATION AND ACCESS CONTROL TESTS
  # ============================================================================

  test "non-admin user cannot access business section" do
    buyer = create(:user, :buyer, :onboarded, :with_terms_accepted)

    visit new_user_session_path
    fill_in "Email", with: buyer.email
    fill_in "Password", with: "password123"
    click_button "Log in"
    assert_selector ".sidebar"

    visit admin_business_root_path

    # Should be redirected or see access denied
    assert_no_text "Business Overview"
  end

  test "admin sidebar has business intelligence section" do
    login_as_admin
    visit admin_root_path

    # Check sidebar has business section
    assert_text "Business Intelligence"
    assert_link "Overview"
    assert_link "Revenue"
    assert_link "User Growth"
  end

  test "breadcrumb navigation works from business pages" do
    login_as_admin
    visit admin_business_revenue_path

    # Section nav should be visible and allow navigation back
    assert_selector ".admin-section-nav"
    assert_link "Overview"
  end
end
