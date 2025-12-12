# frozen_string_literal: true

require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  test "factory creates valid review" do
    reviewer = create(:user)
    reviewee = create(:user)
    review = build(:review, reviewer: reviewer, reviewee: reviewee)
    assert review.valid?, review.errors.full_messages.join(", ")
  end

  test "requires reviewer" do
    review = build(:review, reviewer: nil)
    assert_not review.valid?
  end

  test "requires reviewee" do
    review = build(:review, reviewee: nil)
    assert_not review.valid?
  end

  test "requires reviewee_role" do
    review = build(:review, reviewee_role: nil)
    assert_not review.valid?
  end

  test "requires overall_rating" do
    review = build(:review, overall_rating: nil)
    assert_not review.valid?
  end

  test "requires body" do
    review = build(:review, body: nil)
    assert_not review.valid?
  end

  test "overall_rating must be between 1 and 5" do
    reviewer = create(:user)
    reviewee = create(:user)

    invalid_low = build(:review, reviewer: reviewer, reviewee: reviewee, overall_rating: 0)
    assert_not invalid_low.valid?

    invalid_high = build(:review, reviewer: reviewer, reviewee: reviewee, overall_rating: 6)
    assert_not invalid_high.valid?

    valid = build(:review, reviewer: reviewer, reviewee: reviewee, overall_rating: 3)
    assert valid.valid?, valid.errors.full_messages.join(", ")
  end

  test "reviewer cannot review themselves" do
    user = create(:user)
    review = build(:review, reviewer: user, reviewee: user)
    assert_not review.valid?
    assert_includes review.errors[:reviewer], "cannot review themselves"
  end

  test "negative review is automatically held" do
    review = create(:review, :negative)
    assert review.held?
    assert review.hold_until.present?
  end

  test "positive review is automatically published" do
    review = create(:review, :positive)
    assert review.published?
  end

  test "negative? returns true for ratings 2 or below" do
    one_star = build(:review, overall_rating: 1)
    two_star = build(:review, overall_rating: 2)
    three_star = build(:review, overall_rating: 3)

    assert one_star.negative?
    assert two_star.negative?
    assert_not three_star.negative?
  end

  test "positive? returns true for ratings 4 or above" do
    four_star = build(:review, overall_rating: 4)
    five_star = build(:review, overall_rating: 5)
    three_star = build(:review, overall_rating: 3)

    assert four_star.positive?
    assert five_star.positive?
    assert_not three_star.positive?
  end

  test "on_hold? returns true when held and not expired" do
    held_review = build(:review, status: "held", hold_until: 24.hours.from_now)
    expired_hold = build(:review, status: "held", hold_until: 1.hour.ago)

    assert held_review.on_hold?
    assert_not expired_hold.on_hold?
  end

  test "publish! changes status to published" do
    review = create(:review, status: "pending")
    review.publish!
    assert review.published?
  end

  test "add_response! adds a public response" do
    review = create(:review)
    review.add_response!("Thank you for your feedback!")
    assert_equal "Thank you for your feedback!", review.public_response
    assert review.public_response_at.present?
  end

  test "stars_display returns correct star representation" do
    five_star = build(:review, overall_rating: 5)
    three_star = build(:review, overall_rating: 3)
    one_star = build(:review, overall_rating: 1)

    assert_equal "★★★★★", five_star.stars_display
    assert_equal "★★★☆☆", three_star.stars_display
    assert_equal "★☆☆☆☆", one_star.stars_display
  end
end
