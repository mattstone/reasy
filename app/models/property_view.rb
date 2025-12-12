# frozen_string_literal: true

class PropertyView < ApplicationRecord
  belongs_to :property, counter_cache: :view_count
  belongs_to :user, optional: true

  validates :viewed_at, presence: true

  scope :today, -> { where("viewed_at >= ?", Time.current.beginning_of_day) }
  scope :this_week, -> { where("viewed_at >= ?", 1.week.ago) }
  scope :this_month, -> { where("viewed_at >= ?", 1.month.ago) }
  scope :by_users, -> { where.not(user_id: nil) }
  scope :anonymous, -> { where(user_id: nil) }
end
