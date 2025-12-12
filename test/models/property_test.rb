# frozen_string_literal: true

require "test_helper"

class PropertyTest < ActiveSupport::TestCase
  test "factory creates valid property" do
    property = build(:property)
    assert property.valid?, property.errors.full_messages.join(", ")
  end

  test "requires user" do
    property = build(:property, user: nil)
    assert_not property.valid?
    assert_includes property.errors[:user], "must exist"
  end

  test "requires street_address" do
    property = build(:property, street_address: nil)
    assert_not property.valid?
    assert_includes property.errors[:street_address], "can't be blank"
  end

  test "requires suburb" do
    property = build(:property, suburb: nil)
    assert_not property.valid?
    assert_includes property.errors[:suburb], "can't be blank"
  end

  test "requires valid state" do
    property = build(:property, state: "XX")
    assert_not property.valid?
    assert_includes property.errors[:state], "is not included in the list"
  end

  test "accepts valid Australian states" do
    Property::AUSTRALIAN_STATES.each do |state|
      property = build(:property, state: state)
      assert property.valid?, "State #{state} should be valid"
    end
  end

  test "requires valid postcode format" do
    property = build(:property, postcode: "123")
    assert_not property.valid?
    assert_includes property.errors[:postcode], "must be 4 digits"
  end

  test "requires property_type" do
    property = build(:property, property_type: nil)
    assert_not property.valid?
    assert_includes property.errors[:property_type], "can't be blank"
  end

  test "requires valid listing_intent" do
    property = build(:property, listing_intent: "invalid")
    assert_not property.valid?
    assert_includes property.errors[:listing_intent], "is not included in the list"
  end

  test "requires valid status" do
    property = build(:property, status: "invalid")
    assert_not property.valid?
    assert_includes property.errors[:status], "is not included in the list"
  end

  test "full_address includes all components" do
    property = build(:property,
      unit_number: "5",
      street_address: "123 Main St",
      suburb: "Sydney",
      state: "NSW",
      postcode: "2000")
    assert_equal "5/ 123 Main St Sydney NSW 2000", property.full_address
  end

  test "full_address without unit number" do
    property = build(:property,
      unit_number: nil,
      street_address: "123 Main St",
      suburb: "Sydney",
      state: "NSW",
      postcode: "2000")
    assert_equal "123 Main St Sydney NSW 2000", property.full_address
  end

  test "price conversion from cents" do
    property = build(:property, price_cents: 850_000_00)
    assert_equal 850_000.0, property.price
  end

  test "price setter converts to cents" do
    property = build(:property)
    property.price = 750_000
    assert_equal 750_000_00, property.price_cents
  end

  test "publish! changes status to active" do
    property = create(:property, status: "draft")
    assert property.publish!
    assert_equal "active", property.reload.status
    assert_not_nil property.published_at
  end

  test "publish! fails if already active" do
    property = create(:property, :active)
    assert_not property.publish!
  end

  test "withdraw! changes status to withdrawn" do
    property = create(:property, :active)
    assert property.withdraw!
    assert_equal "withdrawn", property.reload.status
    assert_not_nil property.withdrawn_at
  end

  test "mark_under_offer! changes status" do
    property = create(:property, :active)
    assert property.mark_under_offer!
    assert_equal "under_offer", property.reload.status
    assert_not_nil property.under_offer_at
  end

  test "mark_sold! changes status and records price" do
    property = create(:property, :under_offer, price_cents: 800_000_00)
    assert property.mark_sold!(sale_price_cents: 850_000_00)
    assert_equal "sold", property.reload.status
    assert_equal 850_000_00, property.price_cents
    assert_not_nil property.sold_at
  end

  test "toggle_love! adds love" do
    property = create(:property)
    user = create(:user)

    result = property.toggle_love!(user)
    assert result
    assert property.loved_by?(user)
    assert_equal 1, property.reload.love_count
  end

  test "toggle_love! removes existing love" do
    property = create(:property)
    user = create(:user)

    property.toggle_love!(user)
    result = property.toggle_love!(user)

    assert_not result
    assert_not property.loved_by?(user)
    assert_equal 0, property.reload.love_count
  end

  test "can_receive_offers? true for active property" do
    property = build(:property, :active, :with_pricing)
    assert property.can_receive_offers?
  end

  test "can_receive_offers? false for hidden price" do
    property = build(:property, :active, price_hidden: true)
    assert_not property.can_receive_offers?
  end

  test "can_receive_offers? false for non-active property" do
    property = build(:property, status: "draft")
    assert_not property.can_receive_offers?
  end

  test "active scope returns active properties" do
    active_property = create(:property, :active)
    draft_property = create(:property, status: "draft")

    assert_includes Property.active, active_property
    assert_not_includes Property.active, draft_property
  end

  test "in_state scope filters by state" do
    nsw_property = create(:property, state: "NSW")
    vic_property = create(:property, state: "VIC")

    assert_includes Property.in_state("NSW"), nsw_property
    assert_not_includes Property.in_state("NSW"), vic_property
  end
end
