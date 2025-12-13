# frozen_string_literal: true

require "application_system_test_case"

# Comprehensive browser tests for Admin Application Health section.
# Tests system dashboard, usage analytics, AI analytics, and audit activity.
#
# Run with: bin/rails test test/system/admin/system_section_test.rb
class Admin::SystemSectionTest < ApplicationSystemTestCase
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
  # SYSTEM DASHBOARD TESTS
  # ============================================================================

  test "admin can access system dashboard" do
    login_as_admin
    visit admin_system_root_path

    assert_selector ".admin-content"
    assert_text "Application Health"
    assert_text "System status, performance, and monitoring"
  end

  test "system dashboard displays status alert" do
    login_as_admin
    visit admin_system_root_path

    # Should show either alerts or "All Systems Operational"
    assert_selector ".admin-alert-banner"
  end

  test "system dashboard displays operational metrics" do
    login_as_admin
    visit admin_system_root_path

    assert_selector ".admin-metric-hero-card", minimum: 4
    assert_text "Active Sessions"
    assert_text "Queue Depth"
    assert_text "Error Rate"
    assert_text "Avg Response Time"
  end

  test "system dashboard displays background jobs status" do
    login_as_admin
    visit admin_system_root_path

    assert_text "Background Jobs Status"
    # Labels may be uppercase in the UI
    assert_text(/pending/i)
    assert_text(/failed/i)
  end

  test "system dashboard displays recent errors panel" do
    login_as_admin
    visit admin_system_root_path

    assert_text "Recent Errors"
    # Either shows errors or "No recent errors"
    assert_selector ".admin-panel"
  end

  test "system dashboard displays quick actions" do
    login_as_admin
    visit admin_system_root_path

    assert_text "Quick Actions"
    assert_link "View Audit Logs"
    assert_link "Platform Usage"
    assert_link "AI Analytics"
    assert_link "Platform Settings"
  end

  test "system dashboard section navigation links exist" do
    login_as_admin
    visit admin_system_root_path

    assert_selector ".admin-section-nav"

    # Verify all navigation links exist
    within(".admin-section-nav") do
      assert_link "System Status"
      assert_link "Platform Usage"
      assert_link "AI Analytics"
      assert_link "Audit Activity"
    end
  end

  # ============================================================================
  # PLATFORM USAGE TESTS
  # ============================================================================

  test "admin can access platform usage page" do
    login_as_admin
    visit admin_system_usage_path

    assert_selector ".admin-content"
    assert_text "Platform Usage"
    assert_text "Activity patterns, page views, and search analytics"
  end

  test "platform usage displays activity metrics" do
    login_as_admin
    visit admin_system_usage_path

    assert_selector ".admin-metric-hero-card", minimum: 4
    assert_text "Actions Today"
    assert_text "Actions This Week"
    assert_text "Actions This Month"
    assert_text "Total Actions"
  end

  test "platform usage displays activity heatmap" do
    login_as_admin
    visit admin_system_usage_path

    assert_selector "[data-controller='d3-chart']", minimum: 1
    assert_text "Hourly Activity"
  end

  test "platform usage displays top actions" do
    login_as_admin
    visit admin_system_usage_path

    assert_text "Top Actions"
    assert_selector ".admin-data-list"
  end

  test "platform usage displays property views chart" do
    login_as_admin
    visit admin_system_usage_path

    assert_text "Property Views"
    assert_selector ".admin-chart-card"
  end

  test "platform usage displays browser stats" do
    login_as_admin
    visit admin_system_usage_path

    assert_text "Browser Usage"
    assert_selector ".admin-panel"
  end

  # ============================================================================
  # AI ANALYTICS TESTS
  # ============================================================================

  test "admin can access AI analytics page" do
    login_as_admin
    visit admin_system_ai_path

    assert_selector ".admin-content"
    assert_text "AI Analytics"
    assert_text "Conversation metrics, assistant usage, and ratings"
  end

  test "AI analytics displays conversation metrics" do
    login_as_admin
    visit admin_system_ai_path

    assert_selector ".admin-metric-hero-card", minimum: 4
    assert_text "Total Conversations"
    assert_text "This Week"
    assert_text "Avg Messages/Convo"
    assert_text "Avg Rating"
  end

  test "AI analytics displays daily volume chart" do
    login_as_admin
    visit admin_system_ai_path

    assert_selector "[data-controller='d3-chart']", minimum: 2
    assert_text "Daily Conversations"
  end

  test "AI analytics displays assistant type distribution" do
    login_as_admin
    visit admin_system_ai_path

    assert_text "By Assistant Type"
    assert_selector ".admin-chart-card"
  end

  test "AI analytics displays rating distribution" do
    login_as_admin
    visit admin_system_ai_path

    assert_text "Rating Distribution"
    assert_selector ".admin-data-list"
  end

  test "AI analytics displays recent conversations" do
    login_as_admin
    visit admin_system_ai_path

    assert_text "Recent Conversations"
    assert_link "View All"
  end

  # ============================================================================
  # AUDIT ACTIVITY TESTS
  # ============================================================================

  test "admin can access audit activity page" do
    login_as_admin
    visit admin_system_audit_path

    assert_selector ".admin-content"
    assert_text "Audit Activity"
    assert_text "Action logs, user activity, and impersonation tracking"
  end

  test "audit activity displays activity metrics" do
    login_as_admin
    visit admin_system_audit_path

    assert_selector ".admin-metric-hero-card", minimum: 4
    assert_text "Actions Today"
    assert_text "This Week"
    assert_text "Active Users Today"
    assert_text "Impersonations"
  end

  test "audit activity displays hourly activity chart" do
    login_as_admin
    visit admin_system_audit_path

    assert_selector "[data-controller='d3-chart']", minimum: 2
    assert_text "Activity by Hour"
  end

  test "audit activity displays role distribution" do
    login_as_admin
    visit admin_system_audit_path

    assert_text "Activity by Role"
    assert_selector ".admin-chart-card"
  end

  test "audit activity displays top actions" do
    login_as_admin
    visit admin_system_audit_path

    assert_text "Top Actions"
    assert_selector ".admin-data-list"
  end

  test "audit activity displays resource breakdown" do
    login_as_admin
    visit admin_system_audit_path

    assert_text "By Resource Type"
    assert_selector ".admin-panel"
  end

  test "audit activity displays recent activity list" do
    login_as_admin
    visit admin_system_audit_path

    assert_text "Recent Activity"
    assert_link "View All"
  end

  test "audit activity displays impersonation log" do
    login_as_admin
    visit admin_system_audit_path

    assert_text "Impersonation Log"
    # Either shows impersonation entries or "No impersonation sessions recorded"
    assert_selector ".admin-panel"
  end

  # ============================================================================
  # NAVIGATION AND ACCESS CONTROL TESTS
  # ============================================================================

  test "non-admin user cannot access system section" do
    buyer = create(:user, :buyer, :onboarded, :with_terms_accepted)

    visit new_user_session_path
    fill_in "Email", with: buyer.email
    fill_in "Password", with: "password123"
    click_button "Log in"
    assert_selector ".sidebar"

    visit admin_system_root_path

    # Should be redirected or see access denied
    assert_no_text "Application Health"
  end

  test "admin sidebar has application health section" do
    login_as_admin
    visit admin_root_path

    assert_text "Application Health"
    assert_link "System Status"
    assert_link "Platform Usage"
    assert_link "AI Analytics"
    assert_link "Audit Activity"
  end

  test "quick action links exist on system dashboard" do
    login_as_admin
    visit admin_system_root_path

    assert_text "Quick Actions"
    assert_link "View Audit Logs"
    assert_link "Platform Usage"
    assert_link "AI Analytics"
    assert_link "Platform Settings"
  end
end
