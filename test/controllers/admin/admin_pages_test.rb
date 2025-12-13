# frozen_string_literal: true

require "test_helper"

class Admin::AdminPagesTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!
    @admin = create(:user, :admin, :onboarded, :with_terms_accepted,
                    email: "test_admin_#{SecureRandom.hex(4)}@example.com")
    login_as(@admin, scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  # ============================================================================
  # DASHBOARD TESTS
  # ============================================================================

  test "admin dashboard loads successfully" do
    get admin_dashboard_path
    assert_response :success
  end

  # ============================================================================
  # MANAGE DATA SECTION TESTS
  # ============================================================================

  test "admin users index loads successfully" do
    get admin_users_path
    assert_response :success
  end

  test "admin properties index loads successfully" do
    get admin_properties_path
    assert_response :success
  end

  test "admin transactions index loads successfully" do
    get admin_transactions_path
    assert_response :success
  end

  test "admin reviews index loads successfully" do
    get admin_reviews_path
    assert_response :success
  end

  test "admin audit logs index loads successfully" do
    get admin_audit_logs_path
    assert_response :success
  end

  # ============================================================================
  # BUSINESS INTELLIGENCE SECTION TESTS
  # ============================================================================

  test "admin business root loads successfully" do
    get admin_business_root_path
    assert_response :success
  end

  test "admin business revenue loads successfully" do
    get admin_business_revenue_path
    assert_response :success
  end

  test "admin business users loads successfully" do
    get admin_business_users_path
    assert_response :success
  end

  test "admin business transactions loads successfully" do
    get admin_business_transactions_path
    assert_response :success
  end

  # ============================================================================
  # SYSTEM HEALTH SECTION TESTS
  # ============================================================================

  test "admin system root loads successfully" do
    get admin_system_root_path
    assert_response :success
  end

  test "admin system usage loads successfully" do
    get admin_system_usage_path
    assert_response :success
  end

  test "admin system ai loads successfully" do
    get admin_system_ai_path
    assert_response :success
  end

  test "admin system audit loads successfully" do
    get admin_system_audit_path
    assert_response :success
  end

  # ============================================================================
  # SETTINGS SECTION TESTS
  # ============================================================================

  test "admin ai conversations loads successfully" do
    get admin_ai_conversations_path
    assert_response :success
  end
end
