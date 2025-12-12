# frozen_string_literal: true

require "application_system_test_case"

class UserDashboardsTest < ApplicationSystemTestCase
  setup do
    @admin = User.find_by(email: "admin@reasy.com.au")
    @buyer = User.find_by(email: "buyer@reasy.com.au")
    @seller = User.find_by(email: "seller@reasy.com.au")
    @provider = User.find_by(email: "provider@reasy.com.au")
    @both = User.find_by(email: "both@reasy.com.au")
  end

  test "admin can login and view dashboard" do
    skip "Run db:seed first" unless @admin

    visit new_user_session_path
    fill_in "Email", with: "admin@reasy.com.au"
    fill_in "Password", with: "password123"
    click_button "Log in"

    assert_text "Welcome back"
  end

  test "buyer can login and view dashboard" do
    skip "Run db:seed first" unless @buyer

    visit new_user_session_path
    fill_in "Email", with: "buyer@reasy.com.au"
    fill_in "Password", with: "password123"
    click_button "Log in"

    assert_text "Welcome back"
  end

  test "seller can login and view dashboard" do
    skip "Run db:seed first" unless @seller

    visit new_user_session_path
    fill_in "Email", with: "seller@reasy.com.au"
    fill_in "Password", with: "password123"
    click_button "Log in"

    assert_text "Welcome back"
  end

  test "provider can login and view dashboard" do
    skip "Run db:seed first" unless @provider

    visit new_user_session_path
    fill_in "Email", with: "provider@reasy.com.au"
    fill_in "Password", with: "password123"
    click_button "Log in"

    assert_text "Welcome back"
  end

  test "both roles user can login and view dashboard" do
    skip "Run db:seed first" unless @both

    visit new_user_session_path
    fill_in "Email", with: "both@reasy.com.au"
    fill_in "Password", with: "password123"
    click_button "Log in"

    assert_text "Welcome back"
  end

  test "admin can access admin dashboard" do
    skip "Run db:seed first" unless @admin

    visit new_user_session_path
    fill_in "Email", with: "admin@reasy.com.au"
    fill_in "Password", with: "password123"
    click_button "Log in"

    # Wait for dashboard to load before navigating
    assert_text "Welcome back"

    visit admin_root_path
    assert_text "Admin Dashboard"
  end
end
