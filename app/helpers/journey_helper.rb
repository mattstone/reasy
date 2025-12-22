# frozen_string_literal: true

module JourneyHelper
  # Render a level badge with the user's current level and title
  def journey_level_badge(user)
    return "" unless user

    level = user.journey_level || 1
    title = user.journey_title || "Property Newcomer"

    tag.span(class: "journey-level-badge level-#{level}") do
      concat tag.span("Level #{level}", class: "journey-level-number")
      concat tag.span(title, class: "journey-level-title")
    end
  end

  # Render a compact level indicator (just level number)
  def journey_level_compact(user)
    return "" unless user

    level = user.journey_level || 1
    tag.span("Lv#{level}", class: "journey-level-compact level-#{level}")
  end

  # Render a progress bar showing progress to next level
  def journey_progress_bar(user)
    return "" unless user

    percentage = user.level_progress_percentage || 0
    points_needed = user.points_to_next_level || 0
    current_points = user.journey_points || 0

    tag.div(class: "journey-progress-container") do
      concat tag.div(class: "journey-progress-bar") {
        tag.div(class: "journey-progress-fill", style: "width: #{percentage}%")
      }
      concat tag.span("#{current_points} pts", class: "journey-progress-current")
      if points_needed > 0
        concat tag.span("#{points_needed} to next level", class: "journey-progress-remaining")
      else
        concat tag.span("Max level!", class: "journey-progress-max")
      end
    end
  end

  # Render a circular progress ring
  def journey_progress_ring(user, size: 80)
    return "" unless user

    percentage = user.level_progress_percentage || 0
    level = user.journey_level || 1

    # SVG circle calculations
    stroke_width = 6
    radius = (size - stroke_width) / 2
    circumference = 2 * Math::PI * radius
    offset = circumference - (percentage / 100.0 * circumference)

    tag.div(class: "journey-progress-ring", style: "width: #{size}px; height: #{size}px;") do
      concat tag.svg(width: size, height: size, viewBox: "0 0 #{size} #{size}") {
        safe_join([
          tag.circle(
            class: "ring-background",
            cx: size / 2, cy: size / 2, r: radius,
            fill: "none", stroke: "#e5e7eb", "stroke-width": stroke_width
          ),
          tag.circle(
            class: "ring-progress",
            cx: size / 2, cy: size / 2, r: radius,
            fill: "none", stroke: level_color(level), "stroke-width": stroke_width,
            "stroke-dasharray": circumference, "stroke-dashoffset": offset,
            "stroke-linecap": "round",
            transform: "rotate(-90 #{size / 2} #{size / 2})"
          )
        ])
      }
      concat tag.span(level.to_s, class: "ring-level")
    end
  end

  # Render an achievement badge
  def achievement_badge(achievement)
    return "" unless achievement

    tag.div(class: "achievement-badge #{achievement.achievement_type}") do
      concat tag.span(achievement_icon(achievement.achievement_type), class: "achievement-icon")
      concat tag.span(achievement.title, class: "achievement-title")
    end
  end

  # Render a small achievement icon
  def achievement_icon(achievement_type)
    icons = {
      "first_login" => "star",
      "profile_complete" => "user-check",
      "first_search" => "search",
      "first_enquiry" => "message-circle",
      "first_offer" => "dollar-sign",
      "pre_approved" => "credit-card",
      "first_property_listed" => "home",
      "first_offer_received" => "inbox",
      "first_sale" => "award"
    }
    icons[achievement_type.to_s] || "award"
  end

  # Get background color for achievement type
  def achievement_background_color(achievement_type)
    colors = {
      "first_login" => "#FEF3C7",
      "profile_complete" => "#DBEAFE",
      "first_search" => "#E0E7FF",
      "first_enquiry" => "#D1FAE5",
      "first_offer" => "#FCE7F3",
      "pre_approved" => "#F3E8FF",
      "first_property_listed" => "#CCFBF1",
      "first_offer_received" => "#CFFAFE",
      "first_sale" => "#FEF3C7"
    }
    colors[achievement_type.to_s] || "#F5F5F5"
  end

  # Get color for level (gradient from green to gold)
  def level_color(level)
    colors = {
      1 => "#6b7280",  # Gray
      2 => "#10b981",  # Green
      3 => "#14b8a6",  # Teal
      4 => "#06b6d4",  # Cyan
      5 => "#3b82f6",  # Blue
      6 => "#6366f1",  # Indigo
      7 => "#8b5cf6",  # Violet
      8 => "#a855f7",  # Purple
      9 => "#ec4899",  # Pink
      10 => "#f59e0b"  # Gold
    }
    colors[level] || colors[1]
  end

  # Format points with abbreviation for large numbers
  def format_points(points)
    return "0" unless points

    if points >= 1000
      "#{(points / 1000.0).round(1)}k"
    else
      points.to_s
    end
  end

  # Render checklist item with completion toggle
  def checklist_item_tag(progress, item)
    completed = progress&.completed_item_ids&.include?(item.id) || false
    points = item.points_value || 10

    tag.div(class: "checklist-item #{completed ? 'completed' : ''}", data: { item_id: item.id }) do
      concat tag.div(class: "checklist-checkbox") {
        if completed
          tag.span(class: "checkbox-checked") { "done" }
        else
          tag.span(class: "checkbox-unchecked")
        end
      }
      concat tag.div(class: "checklist-content") {
        safe_join([
          tag.span(item.title, class: "checklist-title"),
          item.description.present? ? tag.span(item.description, class: "checklist-description") : nil
        ].compact)
      }
      concat tag.span("+#{points}", class: "checklist-points")
    end
  end

  # Get completion percentage for a checklist
  def checklist_completion_percentage(progress, total_items)
    return 0 if total_items.zero? || progress.nil?

    completed = progress.completed_item_ids&.size || 0
    ((completed.to_f / total_items) * 100).round
  end

  # Render a mini journey stats block
  def journey_stats_mini(user)
    return "" unless user

    tag.div(class: "journey-stats-mini") do
      concat journey_progress_ring(user, size: 60)
      concat tag.div(class: "journey-stats-text") {
        safe_join([
          tag.span(user.journey_title || "Property Newcomer", class: "stats-title"),
          tag.span("#{user.journey_points || 0} points", class: "stats-points")
        ])
      }
    end
  end
end
