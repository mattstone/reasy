# frozen_string_literal: true

require "test_helper"

class OfferTest < ActiveSupport::TestCase
  test "factory creates valid offer" do
    offer = build(:offer)
    assert offer.valid?, offer.errors.full_messages.join(", ")
  end

  test "requires property" do
    offer = build(:offer, property: nil)
    assert_not offer.valid?
    assert_includes offer.errors[:property], "must exist"
  end

  test "requires buyer" do
    offer = build(:offer, buyer: nil)
    assert_not offer.valid?
    assert_includes offer.errors[:buyer], "must exist"
  end

  test "requires amount_cents" do
    offer = build(:offer, amount_cents: nil)
    assert_not offer.valid?
    assert_includes offer.errors[:amount_cents], "can't be blank"
  end

  test "amount_cents must be positive" do
    offer = build(:offer, amount_cents: 0)
    assert_not offer.valid?
    assert_includes offer.errors[:amount_cents], "must be greater than 0"
  end

  test "requires finance_type" do
    offer = build(:offer, finance_type: nil)
    assert_not offer.valid?
    assert_includes offer.errors[:finance_type], "can't be blank"
  end

  test "requires settlement_days" do
    offer = build(:offer, settlement_days: nil)
    assert_not offer.valid?
    assert_includes offer.errors[:settlement_days], "can't be blank"
  end

  test "buyer cannot be seller" do
    user = create(:user)
    property = create(:property, user: user)
    offer = build(:offer, property: property, buyer: user)

    assert_not offer.valid?
    assert_includes offer.errors[:buyer], "cannot make an offer on their own property"
  end

  test "property must be active on create" do
    property = create(:property, status: "draft")
    offer = build(:offer, property: property)

    assert_not offer.valid?
    assert_includes offer.errors[:property], "is not accepting offers"
  end

  test "amount conversion from cents" do
    offer = build(:offer, amount_cents: 850_000_00)
    assert_equal 850_000.0, offer.amount
  end

  test "amount setter converts to cents" do
    offer = build(:offer)
    offer.amount = 750_000
    assert_equal 750_000_00, offer.amount_cents
  end

  test "has_conditions? returns true when conditions present" do
    offer = build(:offer, :with_conditions)
    assert offer.has_conditions?
  end

  test "has_conditions? returns false when unconditional" do
    offer = build(:offer, :unconditional)
    assert_not offer.has_conditions?
  end

  test "conditions_list returns all conditions" do
    offer = build(:offer,
      subject_to_finance: true,
      subject_to_building_inspection: true,
      subject_to_pest_inspection: false)

    conditions = offer.conditions_list
    assert_includes conditions, "Finance"
    assert_includes conditions, "Building Inspection"
    assert_not_includes conditions, "Pest Inspection"
  end

  test "submit! changes status to submitted" do
    offer = create(:offer, status: "draft")
    assert offer.submit!
    assert_equal "submitted", offer.reload.status
    assert_not_nil offer.submitted_at
  end

  test "submit! fails if not draft" do
    offer = create(:offer, :submitted)
    assert_not offer.submit!
  end

  test "mark_viewed! changes status to viewed" do
    offer = create(:offer, :submitted)
    assert offer.mark_viewed!
    assert_equal "viewed", offer.reload.status
    assert_not_nil offer.viewed_at
  end

  test "accept! creates transaction" do
    property = create(:property, :active, :with_pricing)
    offer = create(:offer, :submitted, property: property)

    assert_difference "Transaction.count", 1 do
      offer.accept!
    end

    assert_equal "accepted", offer.reload.status
    assert_equal "under_offer", property.reload.status
  end

  test "reject! changes status to rejected" do
    offer = create(:offer, :submitted)
    assert offer.reject!(seller_response: "Not interested")
    assert_equal "rejected", offer.reload.status
    assert_equal "Not interested", offer.seller_response
  end

  test "withdraw! changes status to withdrawn" do
    offer = create(:offer, :submitted)
    assert offer.withdraw!
    assert_equal "withdrawn", offer.reload.status
    assert_not_nil offer.withdrawn_at
  end

  test "finalized? returns true for final statuses" do
    %w[accepted rejected withdrawn expired].each do |status|
      offer = build(:offer, status: status)
      assert offer.finalized?, "#{status} should be finalized"
    end
  end

  test "finalized? returns false for active statuses" do
    %w[draft submitted viewed].each do |status|
      offer = build(:offer, status: status)
      assert_not offer.finalized?, "#{status} should not be finalized"
    end
  end

  test "cash? returns true for cash offers" do
    offer = build(:offer, :cash)
    assert offer.cash?
  end

  test "pre_approved? returns true for pre-approved finance" do
    offer = build(:offer, :pre_approved)
    assert offer.pre_approved?
  end

  test "expires_at is set on creation" do
    offer = create(:offer)
    assert_not_nil offer.expires_at
    assert offer.expires_at > Time.current
  end
end
