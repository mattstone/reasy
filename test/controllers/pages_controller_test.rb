# frozen_string_literal: true

require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get root_path
    assert_response :success
    assert_select "h1", /Finally, someone/
  end

  test "should get about" do
    get about_path
    assert_response :success
    assert_select "h1", "About Reasy"
  end

  test "should get how_it_works" do
    get how_it_works_path
    assert_response :success
    assert_select "h1", "How Reasy Works"
  end

  test "should get pricing" do
    get pricing_path
    assert_response :success
    assert_select "h1", /Pricing/
  end

  test "should get contact" do
    get contact_path
    assert_response :success
    assert_select "h1", "Contact Us"
  end
end
