# frozen_string_literal: true

module Admin
  class SystemMetricsService
    # Active Sessions Count (approximation using recent activity)
    def active_sessions_count
      # Users who have been active in the last 15 minutes
      User.where("last_sign_in_at >= ?", 15.minutes.ago).count
    rescue StandardError
      0
    end

    # Background Jobs Queue Depth
    def background_jobs_queue_depth
      SolidQueue::Job.where(finished_at: nil).count
    rescue StandardError
      0
    end

    # Error Rate (24 hours) - based on failed jobs as proxy
    def error_rate_24h
      total_jobs = SolidQueue::Job.where("created_at >= ?", 24.hours.ago).count
      return 0 if total_jobs.zero?

      failed = SolidQueue::FailedExecution.where("created_at >= ?", 24.hours.ago).count
      ((failed.to_f / total_jobs) * 100).round(2)
    rescue StandardError
      0
    end

    # Average Response Time (placeholder - would need request logging)
    def average_response_time
      # This would require middleware to track request times
      # Returning placeholder
      "N/A"
    end

    # Recent Errors
    def recent_errors(limit = 5)
      SolidQueue::FailedExecution.order(created_at: :desc)
                                  .limit(limit)
                                  .map do |fe|
        {
          job_class: fe.job&.class_name || "Unknown",
          error: fe.error&.truncate(100) || "No error message",
          created_at: fe.created_at
        }
      end
    rescue StandardError
      []
    end

    # Property Views Trend (using audit logs as proxy)
    def property_views_trend(days)
      AuditLog.where("created_at >= ?", days.days.ago)
              .where(action_type: "property.viewed")
              .group_by_day(:created_at)
              .count
              .map { |date, count| { date: date.to_s, value: count } }
    rescue StandardError
      []
    end

    # Search Activity
    def search_activity(days)
      AuditLog.where("created_at >= ?", days.days.ago)
              .where("action_type LIKE ?", "%search%")
              .group_by_day(:created_at)
              .count
              .map { |date, count| { date: date.to_s, value: count } }
    rescue StandardError
      []
    end

    # Hourly Activity Heatmap
    def hourly_activity_heatmap
      days_of_week = %w[Sun Mon Tue Wed Thu Fri Sat]

      data = AuditLog.where("created_at >= ?", 7.days.ago)
                     .group_by_day_of_week(:created_at)
                     .group_by_hour_of_day(:created_at)
                     .count

      result = []
      days_of_week.each_with_index do |day, day_idx|
        (0..23).each do |hour|
          result << {
            x: hour.to_s.rjust(2, "0") + ":00",
            y: day,
            value: data[[day_idx, hour]] || 0
          }
        end
      end
      result
    rescue StandardError
      []
    end

    # AI Average Response Time (placeholder)
    def ai_avg_response_time
      # Would need to track response times on AI conversations
      "N/A"
    end
  end
end
