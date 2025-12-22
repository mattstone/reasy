# frozen_string_literal: true

class UserAchievement < ApplicationRecord
  ACHIEVEMENT_TYPES = %w[
    milestone
    streak
    speed_bonus
    level_up
    first_completion
    phase_complete
    journey_complete
    early_bird
    comeback
  ].freeze

  belongs_to :user
  belongs_to :context, polymorphic: true, optional: true

  validates :achievement_type, presence: true, inclusion: { in: ACHIEVEMENT_TYPES }
  validates :title, presence: true
  validates :points_earned, numericality: { greater_than_or_equal_to: 0 }

  scope :by_type, ->(type) { where(achievement_type: type) }
  scope :recent, -> { order(earned_at: :desc) }
  scope :with_points, -> { where("points_earned > 0") }
  scope :milestones, -> { by_type("milestone") }
  scope :level_ups, -> { by_type("level_up") }
  scope :earned_today, -> { where(earned_at: Time.current.all_day) }
  scope :earned_this_week, -> { where(earned_at: Time.current.all_week) }

  before_create :set_earned_at

  # Achievement type helpers
  def milestone?
    achievement_type == "milestone"
  end

  def streak?
    achievement_type == "streak"
  end

  def speed_bonus?
    achievement_type == "speed_bonus"
  end

  def level_up?
    achievement_type == "level_up"
  end

  def first_completion?
    achievement_type == "first_completion"
  end

  def phase_complete?
    achievement_type == "phase_complete"
  end

  def journey_complete?
    achievement_type == "journey_complete"
  end

  # Award an achievement to a user
  def self.award!(user:, achievement_type:, title:, description: nil, points: 0, badge_icon: nil, context: nil)
    achievement = create!(
      user: user,
      achievement_type: achievement_type,
      title: title,
      description: description,
      points_earned: points,
      badge_icon: badge_icon,
      context: context,
      earned_at: Time.current
    )

    # Update user points
    user.increment!(:journey_points, points) if points.positive?
    user.recalculate_level!

    achievement
  end

  # Predefined achievement creators
  def self.award_level_up!(user, new_level, new_title)
    award!(
      user: user,
      achievement_type: "level_up",
      title: "Level Up!",
      description: "Congratulations! You've reached Level #{new_level}: #{new_title}",
      points: 25,
      badge_icon: level_badge(new_level)
    )
  end

  def self.award_milestone!(user, milestone_name, context: nil)
    award!(
      user: user,
      achievement_type: "milestone",
      title: milestone_name,
      description: "You've completed a major milestone in your property journey!",
      points: 50,
      badge_icon: "🏆",
      context: context
    )
  end

  def self.award_streak!(user, streak_days)
    award!(
      user: user,
      achievement_type: "streak",
      title: "#{streak_days}-Day Streak!",
      description: "You've made progress for #{streak_days} consecutive days!",
      points: streak_days * 10,
      badge_icon: "🔥"
    )
  end

  def self.award_speed_bonus!(user, item_name, context: nil)
    award!(
      user: user,
      achievement_type: "speed_bonus",
      title: "Speed Bonus!",
      description: "Completed '#{item_name}' within 24 hours of it becoming available!",
      points: 5,
      badge_icon: "⚡",
      context: context
    )
  end

  def self.award_phase_complete!(user, phase_name, context: nil)
    award!(
      user: user,
      achievement_type: "phase_complete",
      title: "#{phase_name} Complete!",
      description: "You've completed all items in the #{phase_name} phase!",
      points: 100,
      badge_icon: "✅",
      context: context
    )
  end

  def self.award_journey_complete!(user, journey_type, context: nil)
    type_name = journey_type.to_s.titleize
    award!(
      user: user,
      achievement_type: "journey_complete",
      title: "#{type_name} Journey Complete!",
      description: "Congratulations! You've completed your entire #{type_name.downcase} journey!",
      points: 500,
      badge_icon: "🎉",
      context: context
    )
  end

  private

  def set_earned_at
    self.earned_at ||= Time.current
  end

  def self.level_badge(level)
    badges = {
      1 => "🌱", 2 => "🌿", 3 => "🌳", 4 => "🏠", 5 => "🏡",
      6 => "⭐", 7 => "🌟", 8 => "💫", 9 => "👑", 10 => "🏆"
    }
    badges[level] || "🎖️"
  end
end
