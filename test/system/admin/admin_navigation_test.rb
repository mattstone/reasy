# frozen_string_literal: true

require "application_system_test_case"

# Browser tests for admin navigation and section access.
# Run with: bin/rails test test/system/admin/admin_navigation_test.rb
class Admin::AdminNavigationTest < ApplicationSystemTestCase
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
  # ADMIN ROOT ACCESS TESTS
  # ============================================================================

  test "admin can access main admin dashboard" do
    login_as_admin
    visit admin_root_path

    assert_selector ".admin-content"
    assert_text "Admin Dashboard"
  end

  # ============================================================================
  # SIDEBAR NAVIGATION TESTS
  # ============================================================================

  test "admin sidebar displays all sections" do
    login_as_admin
    visit admin_root_path

    assert_text "Business Intelligence"
    assert_text "Application Health"
    assert_text "Manage Data"
    assert_text "Settings"
  end

  test "sidebar has navigation links" do
    login_as_admin
    visit admin_root_path

    within(".dashboard-sidebar") do
      # Business section
      assert_link "Revenue"
      assert_link "User Growth"

      # System section
      assert_link "System Status"
      assert_link "Platform Usage"

      # Manage section
      assert_link "Users"
      assert_link "Properties"

      # Settings
      assert_link "Platform Settings"
    end
  end

  # ============================================================================
  # PAGE ACCESS TESTS
  # ============================================================================

  test "business pages are accessible" do
    login_as_admin

    visit admin_business_root_path
    assert_text "Business Intelligence"

    visit admin_business_revenue_path
    assert_text "Revenue Analytics"

    visit admin_business_users_path
    assert_text "User Growth"

    visit admin_business_transactions_path
    assert_text "Transaction Analytics"
  end

  test "system dashboard is accessible" do
    login_as_admin
    visit admin_system_root_path
    assert_text "Application Health"
  end

  test "platform usage page is accessible" do
    login_as_admin
    visit admin_system_usage_path
    assert_text "Platform Usage"
  end

  test "ai analytics page is accessible" do
    login_as_admin
    visit admin_system_ai_path
    assert_text "AI Analytics"
  end

  test "audit activity page is accessible" do
    login_as_admin
    visit admin_system_audit_path
    assert_text "Audit Activity"
  end

  test "manage data pages are accessible" do
    login_as_admin

    visit admin_users_path
    assert_selector ".admin-content"

    visit admin_properties_path
    assert_selector ".admin-content"

    visit admin_audit_logs_path
    assert_selector ".admin-content"
  end

  # ============================================================================
  # SECTION NAVIGATION TESTS
  # ============================================================================

  test "business section has tab navigation" do
    login_as_admin
    visit admin_business_root_path

    assert_selector ".admin-section-nav"
    within(".admin-section-nav") do
      assert_link "Overview"
      assert_link "Revenue"
      assert_link "User Growth"
      assert_link "Transactions"
    end
  end

  test "system section has tab navigation" do
    login_as_admin
    visit admin_system_root_path

    assert_selector ".admin-section-nav"
    within(".admin-section-nav") do
      assert_link "System Status"
      assert_link "Platform Usage"
      assert_link "AI Analytics"
      assert_link "Audit Activity"
    end
  end

  # ============================================================================
  # PAGE STRUCTURE TESTS
  # ============================================================================

  test "business pages have correct structure" do
    login_as_admin

    visit admin_business_root_path
    assert_selector ".admin-page-title"
    assert_selector ".admin-metric-hero"
  end

  test "system pages have correct structure" do
    login_as_admin

    visit admin_system_root_path
    assert_selector ".admin-page-title"
    assert_selector ".admin-alert-banner"
  end
end
