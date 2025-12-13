# frozen_string_literal: true

require "application_system_test_case"

# Browser tests for D3.js chart rendering in the admin section.
# Run with: bin/rails test test/system/admin/d3_charts_test.rb
class Admin::D3ChartsTest < ApplicationSystemTestCase
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
  # CHART CONTAINER TESTS
  # ============================================================================

  test "business dashboard has chart containers" do
    login_as_admin
    visit admin_business_root_path

    assert_selector "[data-controller='d3-chart']", minimum: 1
    assert_selector ".admin-chart-card", minimum: 1
  end

  test "system usage page has chart containers" do
    login_as_admin
    visit admin_system_usage_path

    assert_selector "[data-controller='d3-chart']", minimum: 1
  end

  test "AI analytics page has chart containers" do
    login_as_admin
    visit admin_system_ai_path

    assert_selector "[data-controller='d3-chart']", minimum: 1
  end

  test "audit activity page has chart containers" do
    login_as_admin
    visit admin_system_audit_path

    assert_selector "[data-controller='d3-chart']", minimum: 1
  end

  # ============================================================================
  # CHART DATA TESTS
  # ============================================================================

  test "charts have required data attributes" do
    login_as_admin
    visit admin_business_root_path

    chart = find("[data-controller='d3-chart']", match: :first)

    # Each chart should have a type
    assert chart["data-d3-chart-type-value"].present?

    # Each chart should have data
    assert chart["data-d3-chart-data-value"].present?

    # Each chart should have a height
    assert chart["data-d3-chart-height-value"].present?
  end

  test "chart data is valid JSON" do
    login_as_admin
    visit admin_business_root_path

    chart = find("[data-controller='d3-chart']", match: :first)
    data = chart["data-d3-chart-data-value"]

    parsed = JSON.parse(data) rescue nil
    assert parsed, "Chart data should be valid JSON"
  end

  # ============================================================================
  # PAGE-SPECIFIC TESTS
  # ============================================================================

  test "business dashboard has revenue and transaction charts" do
    login_as_admin
    visit admin_business_root_path

    assert_text "Revenue Trend"
    assert_text "Transactions by Status"
  end

  test "user growth page has signup and role charts" do
    login_as_admin
    visit admin_business_users_path

    assert_text "Daily Signups"
    assert_text "Users by Role"
  end

  test "AI analytics page has conversation charts" do
    login_as_admin
    visit admin_system_ai_path

    assert_text "Daily Conversations"
    assert_text "By Assistant Type"
  end

  test "audit page has activity charts" do
    login_as_admin
    visit admin_system_audit_path

    assert_text "Activity by Hour"
    assert_text "Activity by Role"
  end

  # ============================================================================
  # EMPTY DATA HANDLING
  # ============================================================================

  test "pages render without errors when data is empty" do
    login_as_admin

    # All these pages should render even with empty data
    visit admin_business_root_path
    assert_selector ".admin-content"

    visit admin_system_ai_path
    assert_selector ".admin-content"

    visit admin_system_audit_path
    assert_selector ".admin-content"
  end
end
