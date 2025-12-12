# frozen_string_literal: true

require "test_helper"

class EntityTest < ActiveSupport::TestCase
  test "factory creates valid individual entity" do
    entity = build(:entity, :individual)
    assert entity.valid?, entity.errors.full_messages.join(", ")
  end

  test "factory creates valid company entity" do
    entity = build(:entity, :company)
    assert entity.valid?, entity.errors.full_messages.join(", ")
  end

  test "factory creates valid SMSF entity" do
    entity = build(:entity, :smsf)
    assert entity.valid?, entity.errors.full_messages.join(", ")
  end

  test "requires user" do
    entity = build(:entity, user: nil)
    assert_not entity.valid?
  end

  test "requires name" do
    entity = build(:entity, name: nil)
    assert_not entity.valid?
    assert_includes entity.errors[:name], "can't be blank"
  end

  test "requires entity_type" do
    entity = build(:entity, entity_type: nil)
    assert_not entity.valid?
  end

  test "validates entity_type inclusion" do
    entity = build(:entity, entity_type: "invalid")
    assert_not entity.valid?
  end

  test "individual requires date_of_birth" do
    entity = build(:entity, :individual, date_of_birth: nil)
    assert_not entity.valid?
    assert_includes entity.errors[:date_of_birth], "can't be blank"
  end

  test "company requires ABN" do
    entity = build(:entity, :company, abn: nil)
    assert_not entity.valid?
    assert_includes entity.errors[:abn], "can't be blank"
  end

  test "company ABN must be 11 digits" do
    entity = build(:entity, :company, abn: "123")
    assert_not entity.valid?
    assert_includes entity.errors[:abn], "must be 11 digits"
  end

  test "SMSF requires fund_name" do
    entity = build(:entity, :smsf, fund_name: nil)
    assert_not entity.valid?
    assert_includes entity.errors[:fund_name], "can't be blank"
  end

  test "SMSF requires fund_abn" do
    entity = build(:entity, :smsf, fund_abn: nil)
    assert_not entity.valid?
    assert_includes entity.errors[:fund_abn], "can't be blank"
  end

  test "individual? returns true for individual entity" do
    entity = build(:entity, :individual)
    assert entity.individual?
    assert_not entity.company?
    assert_not entity.smsf?
  end

  test "company? returns true for company entity" do
    entity = build(:entity, :company)
    assert entity.company?
    assert_not entity.individual?
    assert_not entity.smsf?
  end

  test "smsf? returns true for SMSF entity" do
    entity = build(:entity, :smsf)
    assert entity.smsf?
    assert_not entity.individual?
    assert_not entity.company?
  end

  test "verified? returns true when verified" do
    entity = build(:entity, :individual, :verified)
    assert entity.verified?
  end

  test "first entity becomes default automatically" do
    user = create(:user)
    entity = create(:entity, :individual, user: user, is_default: false)
    assert entity.is_default
  end

  test "make_default! sets entity as default and unsets others" do
    user = create(:user)
    entity1 = create(:entity, :individual, user: user)
    entity2 = create(:entity, :company, user: user, is_default: false)

    entity2.make_default!

    assert entity2.reload.is_default
    assert_not entity1.reload.is_default
  end

  test "display_name returns appropriate name based on type" do
    individual = build(:entity, :individual, name: "John Smith")
    company = build(:entity, :company, name: "John Smith", company_name: "Acme Corp")
    smsf = build(:entity, :smsf, name: "John Smith", fund_name: "Smith Super")

    assert_equal "John Smith", individual.display_name
    assert_equal "Acme Corp", company.display_name
    assert_equal "Smith Super", smsf.display_name
  end
end
