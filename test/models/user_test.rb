# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "factory creates valid user" do
    user = build(:user)
    assert user.valid?, user.errors.full_messages.join(", ")
  end

  test "requires email" do
    user = build(:user, email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires name" do
    user = build(:user, name: nil)
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "sets default roles if empty" do
    # The before_validation callback sets default roles
    user = build(:user, roles: [])
    user.valid?  # triggers before_validation
    # Should have set default role
    assert_includes user.roles, "buyer"
  end

  test "sets default role on create" do
    user = User.new(
      email: "test@example.com",
      name: "Test User",
      password: "password123",
      password_confirmation: "password123"
    )
    user.valid?
    assert_includes user.roles, "buyer"
  end

  test "buyer? returns true for buyer role" do
    user = build(:user, :buyer)
    assert user.buyer?
    assert_not user.seller?
    assert_not user.admin?
  end

  test "seller? returns true for seller role" do
    user = build(:user, :seller)
    assert user.seller?
    assert_not user.buyer?
  end

  test "admin? returns true for admin role" do
    user = build(:user, :admin)
    assert user.admin?
  end

  test "user can have multiple roles" do
    user = build(:user, :buyer_seller)
    assert user.buyer?
    assert user.seller?
    assert_not user.admin?
  end

  test "add_role adds a new role" do
    user = create(:user, :buyer)
    user.add_role(:seller)
    assert user.seller?
    assert user.buyer?
  end

  test "add_role does not add duplicate role" do
    user = create(:user, :buyer)
    user.add_role(:buyer)
    assert_equal 1, user.roles.count("buyer")
  end

  test "remove_role removes a role" do
    user = create(:user, :buyer_seller)
    user.remove_role(:seller)
    assert user.buyer?
    assert_not user.seller?
  end

  test "active_subscription? returns true for trial or active" do
    trial_user = build(:user, :trial)
    subscribed_user = build(:user, :subscribed)
    expired_user = build(:user, subscription_status: "expired")

    assert trial_user.active_subscription?
    assert subscribed_user.active_subscription?
    assert_not expired_user.active_subscription?
  end

  test "trial_expired? returns true when trial has expired" do
    expired_user = build(:user, :trial_expired)
    active_trial_user = build(:user, :trial)

    assert expired_user.trial_expired?
    assert_not active_trial_user.trial_expired?
  end

  test "kyc_verified? returns true when status is verified" do
    verified_user = build(:user, :verified)
    pending_user = build(:user)

    assert verified_user.kyc_verified?
    assert_not pending_user.kyc_verified?
  end
end
