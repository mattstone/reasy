# frozen_string_literal: true

require "application_system_test_case"

class PagesTest < ApplicationSystemTestCase
  test "visiting the home page" do
    visit root_path

    # The hero text uses AOS animations so may not be immediately visible
    # Check for always-visible nav links and footer content instead
    assert_link "Get started free"
    assert_link "How it works"
    assert_text "Real estate made easy"
  end

  test "visiting the about page" do
    visit about_path

    assert_selector "h1", text: "About Reasy"
    assert_text "Our Mission"
  end

  test "visiting the how it works page" do
    visit how_it_works_path

    assert_selector "h1", text: "How Reasy Works"
    assert_text "For Sellers"
    assert_text "For Buyers"
  end

  test "visiting the pricing page" do
    visit pricing_path

    assert_selector "h1", text: "Simple, Transparent Pricing"
    assert_text "For Buyers"
    assert_text "For Sellers"
    assert_text "$4,990"
  end

  test "visiting the contact page" do
    visit contact_path

    assert_selector "h1", text: "Contact Us"
    assert_text "support@reasy.com.au"
    assert_selector "form"
  end

  test "navigation between pages works" do
    visit root_path
    # Home page loads (hero text may be animated)
    assert_link "Get started free"

    visit about_path
    assert_selector "h1", text: "About Reasy"

    visit pricing_path
    assert_selector "h1", text: "Simple, Transparent Pricing"
  end
end
