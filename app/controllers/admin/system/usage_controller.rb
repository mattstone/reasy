# frozen_string_literal: true

module Admin
  module System
    class UsageController < System::BaseController
      def show
        # Page View Metrics (using AuditLog as proxy)
        @page_views_today = AuditLog.today.count
        @page_views_week = AuditLog.this_week.count
        @page_views_month = AuditLog.where("created_at >= ?", 30.days.ago).count

        # Most Common Actions
        @top_actions = AuditLog.where("created_at >= ?", 7.days.ago)
                               .group(:action_type)
                               .count
                               .sort_by { |_, v| -v }
                               .first(10)
                               .to_h

        # Property Views (if tracked)
        @property_views = metrics_service.property_views_trend(30)

        # Search Activity
        @search_queries = metrics_service.search_activity(7)

        # User Sessions by Time
        @hourly_activity = metrics_service.hourly_activity_heatmap

        # Device/Browser breakdown (if tracked via user_agent)
        @user_agents = AuditLog.where("created_at >= ?", 7.days.ago)
                               .where.not(user_agent: nil)
                               .group(:user_agent)
                               .count
                               .transform_keys { |ua| parse_user_agent(ua) }
                               .group_by { |k, _| k }
                               .transform_values { |v| v.sum { |_, count| count } }
      end

      private

      def parse_user_agent(ua)
        return "Unknown" if ua.blank?

        case ua.downcase
        when /chrome/
          "Chrome"
        when /safari/
          "Safari"
        when /firefox/
          "Firefox"
        when /edge/
          "Edge"
        else
          "Other"
        end
      end
    end
  end
end
