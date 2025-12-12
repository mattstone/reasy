module ApplicationHelper
  # Saved Search helpers
  def search_criteria_summary(search)
    parts = []
    criteria = search.criteria || {}

    # Bedrooms
    if criteria["min_bedrooms"].present?
      parts << "#{criteria['min_bedrooms']}+ beds"
    end

    # Property types
    if criteria["property_types"].present? && criteria["property_types"].any?
      types = criteria["property_types"].map(&:humanize)
      parts << (types.length > 2 ? "#{types.first(2).join(', ')}..." : types.join(", "))
    end

    # Location
    if criteria["suburbs"].present? && criteria["suburbs"].any?
      suburbs = criteria["suburbs"]
      parts << (suburbs.length > 2 ? "#{suburbs.first(2).join(', ')}..." : suburbs.join(", "))
    elsif criteria["state"].present?
      parts << criteria["state"]
    end

    # Price
    if criteria["min_price_cents"].present? || criteria["max_price_cents"].present?
      min = criteria["min_price_cents"].present? ? number_to_currency(criteria["min_price_cents"] / 100, precision: 0) : nil
      max = criteria["max_price_cents"].present? ? number_to_currency(criteria["max_price_cents"] / 100, precision: 0) : nil

      if min && max
        parts << "#{min}-#{max}"
      elsif min
        parts << "#{min}+"
      elsif max
        parts << "Up to #{max}"
      end
    end

    parts.any? ? parts.join(" · ") : "All properties"
  end

  def alert_frequency_badge_class(frequency)
    case frequency
    when "instant"
      "badge-orange"
    when "daily"
      "badge-blue"
    when "weekly"
      "badge-gray"
    else
      "badge-gray"
    end
  end

  # Offer helpers
  def offer_status_badge_class(status)
    case status
    when "draft"
      "badge-gray"
    when "submitted", "viewed"
      "badge-blue"
    when "accepted"
      "badge-green"
    when "rejected"
      "badge-red"
    when "countered"
      "badge-orange"
    when "withdrawn"
      "badge-gray"
    when "expired"
      "badge-gray"
    else
      "badge-gray"
    end
  end

  # Notification helpers
  def notification_icon_class(notification_type)
    case notification_type
    when "offer_received", "offer_countered"
      "notification-icon-orange"
    when "offer_accepted"
      "notification-icon-green"
    when "offer_rejected", "offer_expired", "offer_withdrawn"
      "notification-icon-red"
    when "property_view", "property_enquiry", "property_loved"
      "notification-icon-blue"
    when "message_received"
      "notification-icon-purple"
    when "review_received", "review_published"
      "notification-icon-teal"
    when "transaction_update", "document_uploaded"
      "notification-icon-green"
    when "kyc_status_changed"
      "notification-icon-orange"
    when "subscription_reminder"
      "notification-icon-red"
    when "system_announcement"
      "notification-icon-gray"
    else
      "notification-icon-gray"
    end
  end

  def notification_icon(notification_type)
    icons = {
      "offer_received" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2v20M2 12h20"/></svg>',
      "offer_accepted" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>',
      "offer_rejected" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>',
      "offer_countered" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="17 1 21 5 17 9"/><path d="M3 11V9a4 4 0 0 1 4-4h14"/><polyline points="7 23 3 19 7 15"/><path d="M21 13v2a4 4 0 0 1-4 4H3"/></svg>',
      "offer_expired" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>',
      "offer_withdrawn" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>',
      "property_view" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>',
      "property_enquiry" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>',
      "property_loved" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg>',
      "message_received" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>',
      "review_received" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>',
      "review_published" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>',
      "transaction_update" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect width="18" height="18" x="3" y="4" rx="2" ry="2"/><line x1="16" x2="16" y1="2" y2="6"/><line x1="8" x2="8" y1="2" y2="6"/><line x1="3" x2="21" y1="10" y2="10"/></svg>',
      "document_uploaded" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>',
      "kyc_status_changed" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>',
      "subscription_reminder" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect width="20" height="14" x="2" y="5" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/></svg>',
      "system_announcement" => '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>'
    }

    icons[notification_type]&.html_safe || icons["system_announcement"].html_safe
  end

  # KYC helpers
  def kyc_status_badge_class(status)
    case status
    when "pending"
      "badge-orange"
    when "submitted", "under_review"
      "badge-blue"
    when "verified"
      "badge-green"
    when "rejected"
      "badge-red"
    else
      "badge-gray"
    end
  end

  # Document helpers
  def document_visibility_badge_class(visibility)
    case visibility
    when "private"
      "badge-gray"
    when "shared"
      "badge-blue"
    when "public"
      "badge-green"
    else
      "badge-gray"
    end
  end

  # Property helpers
  def property_status_badge_class(status)
    case status
    when "active"
      "badge-green"
    when "pending", "under_review"
      "badge-orange"
    when "draft"
      "badge-gray"
    when "sold"
      "badge-blue"
    when "withdrawn", "expired"
      "badge-red"
    else
      "badge-gray"
    end
  end

  # Subscription helpers
  def subscription_status_badge_class(status)
    case status
    when "active"
      "badge-green"
    when "trial"
      "badge-blue"
    when "past_due"
      "badge-orange"
    when "cancelled", "expired"
      "badge-red"
    when "free"
      "badge-gray"
    else
      "badge-gray"
    end
  end
end
