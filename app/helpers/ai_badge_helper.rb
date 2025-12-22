# frozen_string_literal: true

# Helper methods for rendering AI insight badges on properties
module AIBadgeHelper
  # Render a single AI badge
  def ai_badge(type:, value: nil, label: nil, **options)
    badge_class = ai_badge_class(type, value)
    icon = ai_badge_icon(type)
    display_label = label || ai_badge_label(type, value)

    content_tag(:span, class: "ai-badge #{badge_class} #{options[:class]}".strip) do
      safe_join([
        content_tag(:span, icon, class: "ai-badge-icon"),
        content_tag(:span, display_label, class: "ai-badge-label")
      ])
    end
  end

  # Render all badges for a property
  def ai_badges_for(property, user = nil)
    context = AI::PropertyContextBuilder.new(property, user)
    badges = context.badges

    return nil if badges.empty?

    content_tag(:div, class: "ai-badges") do
      safe_join(badges.first(4).map { |b| ai_badge(**b) })
    end
  end

  # Render match score badge specifically
  def ai_match_badge(score)
    return nil unless score

    quality = case score
              when 80..100 then :excellent
              when 65..79 then :good
              when 50..64 then :moderate
              else :low
    end

    content_tag(:span, class: "ai-badge ai-badge-match ai-badge-match-#{quality}") do
      safe_join([
        content_tag(:span, "#{score}%", class: "ai-badge-score"),
        content_tag(:span, "match", class: "ai-badge-label")
      ])
    end
  end

  # Render Reasy score badge
  def ai_reasy_score_badge(score, band = nil)
    return nil unless score

    band ||= reasy_score_band(score)

    content_tag(:span, class: "ai-badge ai-badge-reasy ai-badge-reasy-#{band}") do
      safe_join([
        content_tag(:span, score.round.to_s, class: "ai-badge-score"),
        content_tag(:span, "Reasy", class: "ai-badge-label")
      ])
    end
  end

  # Render value assessment badge
  def ai_value_badge(assessment)
    return nil unless assessment

    type = assessment.is_a?(Hash) ? assessment[:type] : assessment
    label = case type.to_sym
            when :opportunity then "Below Market"
            when :fair then "Fair Value"
            when :above_market then "Above Market"
            else return nil
    end

    content_tag(:span, class: "ai-badge ai-badge-value ai-badge-value-#{type}") do
      content_tag(:span, label, class: "ai-badge-label")
    end
  end

  # Render risk badge
  def ai_risk_badge(risk)
    return nil unless risk

    type = risk.is_a?(Hash) ? risk[:type] : risk
    label = risk.is_a?(Hash) ? risk[:short_label] : risk.to_s.humanize

    content_tag(:span, class: "ai-badge ai-badge-risk") do
      safe_join([
        content_tag(:span, "!", class: "ai-badge-icon"),
        content_tag(:span, label, class: "ai-badge-label")
      ])
    end
  end

  # Render opportunity badge
  def ai_opportunity_badge(opportunity)
    return nil unless opportunity

    type = opportunity.is_a?(Hash) ? opportunity[:type] : opportunity
    label = opportunity.is_a?(Hash) ? opportunity[:short_label] : opportunity.to_s.humanize

    content_tag(:span, class: "ai-badge ai-badge-opportunity") do
      safe_join([
        content_tag(:span, "+", class: "ai-badge-icon"),
        content_tag(:span, label, class: "ai-badge-label")
      ])
    end
  end

  private

  def ai_badge_class(type, value = nil)
    case type.to_sym
    when :match_score
      quality = case value.to_i
                when 80..100 then "excellent"
                when 65..79 then "good"
                when 50..64 then "moderate"
                else "low"
      end
      "ai-badge-match ai-badge-match-#{quality}"
    when :reasy_score
      "ai-badge-reasy ai-badge-reasy-#{value.is_a?(Hash) ? value[:band] : 'default'}"
    when :value
      "ai-badge-value ai-badge-value-#{value}"
    when :risk
      "ai-badge-risk"
    when :opportunity
      "ai-badge-opportunity"
    else
      "ai-badge-default"
    end
  end

  def ai_badge_icon(type)
    case type.to_sym
    when :match_score then ""
    when :reasy_score then ""
    when :value then ""
    when :risk then "!"
    when :opportunity then "+"
    else ""
    end
  end

  def ai_badge_label(type, value)
    case type.to_sym
    when :match_score then "#{value}% match"
    when :reasy_score then "#{value.is_a?(Hash) ? value[:value] : value} Reasy"
    when :value then value.to_s.humanize
    when :risk then value.to_s.humanize
    when :opportunity then value.to_s.humanize
    else value.to_s
    end
  end

  def reasy_score_band(score)
    case score.to_i
    when 80..100 then :excellent
    when 65..79 then :good
    when 50..64 then :average
    when 35..49 then :below_average
    else :low
    end
  end
end
