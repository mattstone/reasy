# frozen_string_literal: true

class PropertyLove < ApplicationRecord
  belongs_to :user
  belongs_to :property, counter_cache: :love_count

  validates :user_id, uniqueness: { scope: :property_id, message: "has already loved this property" }
end
