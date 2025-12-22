# frozen_string_literal: true

module ScoreHelper
  # Returns CSS class for score badge based on value
  def reasy_score_badge_class(score)
    return "badge-gray" unless score

    case score
    when 80..100 then "badge-green"
    when 65..79 then "badge-blue"
    when 50..64 then "badge-orange"
    else "badge-red"
    end
  end

  # Returns human-readable label for score
  def reasy_score_label(score)
    return "No Data" unless score

    case score
    when 80..100 then "Excellent"
    when 65..79 then "Good"
    when 50..64 then "Average"
    when 35..49 then "Below Average"
    else "Low"
    end
  end

  # Returns CSS class for crime band badge
  def crime_band_badge_class(band)
    case band&.to_s&.downcase
    when "very_low", "low" then "badge-green"
    when "medium" then "badge-orange"
    when "high", "very_high" then "badge-red"
    else "badge-gray"
    end
  end

  # Returns human-readable crime band label
  def crime_band_label(band)
    return "Unknown" unless band

    band.to_s.titleize.gsub("_", " ")
  end

  # Returns hash with trend indicator details
  def crime_trend_indicator(trend)
    case trend&.to_s&.downcase
    when "improving"
      { icon: "trending-down", css_class: "change-badge-positive", label: "Improving" }
    when "worsening"
      { icon: "trending-up", css_class: "change-badge-negative", label: "Worsening" }
    else
      { icon: "minus", css_class: "change-badge-neutral", label: "Stable" }
    end
  end

  # Formats score for display
  def format_score(score)
    return "--" unless score

    score.round.to_s
  end

  # Returns circular progress ring SVG
  def score_ring_svg(score, size: 48, stroke_width: 4)
    return "" unless score

    radius = (size - stroke_width) / 2.0
    circumference = 2 * Math::PI * radius
    offset = circumference - (score / 100.0) * circumference

    color = case score
    when 80..100 then "var(--color-success)"
    when 65..79 then "var(--color-primary)"
    when 50..64 then "var(--color-warning)"
    else "var(--color-error)"
    end

    <<~SVG.html_safe
      <svg width="#{size}" height="#{size}" viewBox="0 0 #{size} #{size}" class="score-ring">
        <circle
          cx="#{size / 2.0}"
          cy="#{size / 2.0}"
          r="#{radius}"
          fill="none"
          stroke="var(--color-gray-200)"
          stroke-width="#{stroke_width}"
        />
        <circle
          cx="#{size / 2.0}"
          cy="#{size / 2.0}"
          r="#{radius}"
          fill="none"
          stroke="#{color}"
          stroke-width="#{stroke_width}"
          stroke-dasharray="#{circumference}"
          stroke-dashoffset="#{offset}"
          stroke-linecap="round"
          transform="rotate(-90 #{size / 2.0} #{size / 2.0})"
        />
      </svg>
    SVG
  end

  # Returns icon class for breakdown item
  def breakdown_icon_class(component)
    case component.to_sym
    when :growth, :growth_score then "metric-card-icon-green"
    when :safety then "metric-card-icon-orange"
    when :transport then "metric-card-icon-blue"
    when :hazard then "metric-card-icon-red"
    when :tenant_quality then "metric-card-icon-purple"
    when :socioeconomic then "metric-card-icon-teal"
    when :rental_yield then "metric-card-icon-cyan"
    when :education then "metric-card-icon-indigo"
    else "metric-card-icon-gray"
    end
  end

  # Returns human-readable label for education score (ICSEA)
  def education_score_label(score)
    return "No Data" unless score

    case score
    when 80..100 then "Excellent Schools"
    when 65..79 then "Good Schools"
    when 50..64 then "Average Schools"
    when 35..49 then "Below Average"
    else "Limited Data"
    end
  end

  # Returns human-readable label for ICSEA value
  def icsea_label(icsea)
    return "No Data" unless icsea

    case icsea
    when 1100..1300 then "Well Above Average"
    when 1050..1099 then "Above Average"
    when 950..1049 then "Average"
    when 850..949 then "Below Average"
    else "Well Below Average"
    end
  end

  # Formats growth percentage
  def format_growth(growth)
    return "--" unless growth
    "#{growth >= 0 ? '+' : ''}#{growth.round(1)}%"
  end

  # Returns CSS class for growth badge
  def growth_badge_class(growth)
    return "badge-gray" unless growth
    growth >= 5 ? "badge-green" : (growth >= 0 ? "badge-blue" : "badge-red")
  end

  # Format component name for display
  def score_component_label(component)
    case component.to_sym
    when :growth, :growth_score then "Growth Potential"
    when :safety then "Safety"
    when :transport then "Transport"
    when :hazard then "Hazard Risk"
    when :education then "Education"
    when :tenant_quality then "Tenant Quality"
    when :socioeconomic then "Economy"
    when :rental_yield then "Rental Yield"
    else component.to_s.humanize
    end
  end

  # Returns the weight percentage for each score component
  def score_component_weight(component)
    case component.to_sym
    when :growth, :growth_score then 20
    when :safety then 15
    when :transport then 15
    when :hazard then 15
    when :education then 10
    when :rental_yield then 10
    when :tenant_quality then 10
    when :socioeconomic then 5
    else 0
    end
  end

  # Transport score helpers
  def transport_score_label(score)
    return "No Data" unless score

    case score
    when 80..100 then "Excellent Access"
    when 65..79 then "Good Access"
    when 50..64 then "Moderate Access"
    when 35..49 then "Limited Access"
    else "Poor Access"
    end
  end

  def transport_score_badge_class(score)
    return "badge-gray" unless score

    case score
    when 80..100 then "badge-green"
    when 65..79 then "badge-blue"
    when 50..64 then "badge-orange"
    else "badge-red"
    end
  end

  def format_distance(km)
    return "--" unless km
    km < 1 ? "#{(km * 1000).round}m" : "#{km.round(1)}km"
  end

  # Hazard score helpers (note: higher score = safer)
  def hazard_score_label(score)
    return "No Data" unless score

    case score
    when 85..100 then "Very Low Risk"
    when 70..84 then "Low Risk"
    when 50..69 then "Moderate Risk"
    when 30..49 then "High Risk"
    else "Very High Risk"
    end
  end

  def hazard_score_badge_class(score)
    return "badge-gray" unless score

    case score
    when 85..100 then "badge-green"
    when 70..84 then "badge-blue"
    when 50..69 then "badge-orange"
    else "badge-red"
    end
  end

  def risk_level_badge_class(risk_level)
    case risk_level&.to_s&.downcase
    when "none" then "badge-green"
    when "low" then "badge-blue"
    when "medium" then "badge-orange"
    when "high" then "badge-red"
    else "badge-gray"
    end
  end

  def risk_level_label(risk_level)
    return "Unknown" unless risk_level
    risk_level.to_s.titleize
  end
end
