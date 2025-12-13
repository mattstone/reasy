# frozen_string_literal: true

module Admin
  module System
    class AuditController < System::BaseController
      def show
        # Primary Metrics
        @actions_today = AuditLog.today.count
        @actions_this_week = AuditLog.this_week.count
        @unique_users_today = AuditLog.today.distinct.count(:user_id)
        @impersonation_sessions = AuditLog.impersonated.this_week.count

        # Top Action Types
        @top_actions = AuditLog.where("created_at >= ?", 7.days.ago)
                               .group(:action_type)
                               .count
                               .sort_by { |_, v| -v }
                               .first(10)
                               .to_h

        # Activity by Resource Type
        @by_resource = AuditLog.where("created_at >= ?", 7.days.ago)
                               .group(:resource_type)
                               .count

        # Activity by Hour (for heatmap)
        @hourly_activity = build_hourly_activity

        # Activity by User Role
        @by_role = calculate_activity_by_role

        # Recent Audit Entries
        @recent_entries = AuditLog.includes(:user, :impersonated_by)
                                  .recent
                                  .limit(20)

        # Impersonation Log
        @recent_impersonations = AuditLog.impersonated
                                         .includes(:user, :impersonated_by)
                                         .order(created_at: :desc)
                                         .limit(10)
      end

      private

      def build_hourly_activity
        data = AuditLog.where("created_at >= ?", 7.days.ago)
                       .group_by_hour_of_day(:created_at)
                       .count

        (0..23).map do |hour|
          {
            x: hour.to_s.rjust(2, "0") + ":00",
            y: "Activity",
            value: data[hour] || 0
          }
        end
      rescue StandardError
        []
      end

      def calculate_activity_by_role
        user_ids = AuditLog.where("created_at >= ?", 7.days.ago)
                           .distinct
                           .pluck(:user_id)
                           .compact

        users = User.where(id: user_ids)

        {
          buyers: users.select(&:buyer?).count,
          sellers: users.select(&:seller?).count,
          providers: users.select(&:service_provider?).count,
          admins: users.select(&:admin?).count
        }
      rescue StandardError
        { buyers: 0, sellers: 0, providers: 0, admins: 0 }
      end
    end
  end
end
