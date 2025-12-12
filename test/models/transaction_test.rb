# frozen_string_literal: true

require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  test "factory creates valid transaction" do
    transaction = build(:transaction)
    assert transaction.valid?, transaction.errors.full_messages.join(", ")
  end

  test "requires property" do
    transaction = build(:transaction, property: nil, skip_offer: true)
    assert_not transaction.valid?
    assert_includes transaction.errors[:property], "must exist"
  end

  test "requires offer" do
    transaction = build(:transaction, offer: nil, skip_offer: true)
    assert_not transaction.valid?
    assert_includes transaction.errors[:offer], "must exist"
  end

  test "requires seller" do
    transaction = build(:transaction, seller: nil, skip_offer: true)
    assert_not transaction.valid?
    assert_includes transaction.errors[:seller], "must exist"
  end

  test "requires buyer" do
    transaction = build(:transaction, buyer: nil, skip_offer: true)
    assert_not transaction.valid?
    assert_includes transaction.errors[:buyer], "must exist"
  end

  test "requires sale_price_cents" do
    transaction = build(:transaction, sale_price_cents: nil)
    assert_not transaction.valid?
    assert_includes transaction.errors[:sale_price_cents], "can't be blank"
  end

  test "sale_price_cents must be positive" do
    transaction = build(:transaction, sale_price_cents: 0)
    assert_not transaction.valid?
    assert_includes transaction.errors[:sale_price_cents], "must be greater than 0"
  end

  test "sale_price returns amount in dollars" do
    transaction = build(:transaction, sale_price_cents: 850_000_00)
    assert_equal 850_000.0, transaction.sale_price
  end

  test "deposit_outstanding? returns true when deposit not fully paid" do
    transaction = build(:transaction, deposit_cents: 85_000_00, deposit_paid_cents: 42_500_00)
    assert transaction.deposit_outstanding?
  end

  test "deposit_outstanding? returns false when fully paid" do
    transaction = build(:transaction, :with_deposit)
    assert_not transaction.deposit_outstanding?
  end

  test "exchange! changes status to exchanged" do
    transaction = create(:transaction, status: "pending")
    assert transaction.exchange!
    assert_equal "exchanged", transaction.reload.status
    assert_equal Date.current, transaction.exchange_date
  end

  test "exchange! fails if not pending" do
    transaction = create(:transaction, :exchanged)
    assert_not transaction.exchange!
  end

  test "start_cooling_off! sets cooling off period" do
    transaction = create(:transaction, :exchanged)
    assert transaction.start_cooling_off!
    assert_equal "cooling_off", transaction.reload.status
    assert_not_nil transaction.cooling_off_ends_at
  end

  test "go_unconditional! changes status" do
    transaction = create(:transaction, status: "cooling_off")
    assert transaction.go_unconditional!
    assert_equal "unconditional", transaction.reload.status
  end

  test "settle! marks transaction as settled" do
    transaction = create(:transaction, :unconditional)
    assert transaction.settle!
    assert_equal "settled", transaction.reload.status
    assert_not_nil transaction.settled_at
    assert_equal "sold", transaction.property.reload.status
  end

  test "fall_through! marks transaction as fallen through" do
    transaction = create(:transaction, :unconditional)
    assert transaction.fall_through!(reason: "Finance failed")
    assert_equal "fallen_through", transaction.reload.status
    assert_equal "Finance failed", transaction.fallen_through_reason
  end

  test "can_rescind? returns true during cooling off" do
    transaction = build(:transaction,
      status: "cooling_off",
      cooling_off_ends_at: 3.days.from_now)
    assert transaction.can_rescind?
  end

  test "can_rescind? returns false after cooling off ends" do
    transaction = build(:transaction,
      status: "cooling_off",
      cooling_off_ends_at: 1.day.ago)
    assert_not transaction.can_rescind?
  end

  test "all_conditions_satisfied? checks all required conditions" do
    offer = create(:offer, :with_conditions)
    transaction = create(:transaction, offer: offer)

    assert_not transaction.all_conditions_satisfied?

    transaction.update!(
      finance_approved: true,
      building_inspection_passed: true,
      pest_inspection_passed: true
    )

    assert transaction.all_conditions_satisfied?
  end

  test "approve_finance! marks finance as approved" do
    transaction = create(:transaction)
    transaction.approve_finance!

    assert transaction.finance_approved?
    assert_not_nil transaction.finance_approved_at
  end

  test "pass_building_inspection! marks inspection passed" do
    transaction = create(:transaction)
    transaction.pass_building_inspection!

    assert transaction.building_inspection_passed?
    assert_not_nil transaction.building_inspection_at
  end

  test "record_deposit_payment! tracks deposits" do
    transaction = create(:transaction, deposit_cents: 85_000_00, deposit_paid_cents: 0)
    transaction.record_deposit_payment!(42_500_00)

    assert_equal 42_500_00, transaction.deposit_paid_cents

    transaction.record_deposit_payment!(42_500_00)
    assert_equal 85_000_00, transaction.deposit_paid_cents
  end

  test "log_event! creates transaction event" do
    transaction = create(:transaction)

    assert_difference "TransactionEvent.count", 1 do
      transaction.log_event!("custom", "Test Event", description: "Test description")
    end

    event = transaction.transaction_events.last
    assert_equal "custom", event.event_type
    assert_equal "Test Event", event.title
  end

  test "days_until_settlement calculates correctly" do
    transaction = build(:transaction, settlement_date: 10.days.from_now.to_date)
    assert_equal 10, transaction.days_until_settlement
  end

  test "overdue? returns true when past settlement" do
    transaction = build(:transaction,
      status: "settling",
      settlement_date: 1.day.ago.to_date)
    assert transaction.overdue?
  end

  test "active scope returns non-completed transactions" do
    active = create(:transaction, :unconditional)
    settled = create(:transaction, :settled)

    assert_includes Transaction.active, active
    assert_not_includes Transaction.active, settled
  end
end
