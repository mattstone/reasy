# frozen_string_literal: true

module Admin
  module System
    class DashboardController < System::BaseController
      def show
        # Hero Metrics
        @active_sessions = metrics_service.active_sessions_count
        @queue_depth = metrics_service.background_jobs_queue_depth
        @error_rate = metrics_service.error_rate_24h
        @avg_response_time = metrics_service.average_response_time

        # System Alerts
        @alerts = build_system_alerts

        # Recent Errors (from logs)
        @recent_errors = metrics_service.recent_errors(5)

        # Background Jobs Status
        @jobs_status = {
          pending: SolidQueue::Job.where(finished_at: nil).count,
          failed: SolidQueue::FailedExecution.count,
          processed_today: SolidQueue::Job.where("finished_at >= ?", Date.current.beginning_of_day).count
        }
      rescue StandardError => e
        Rails.logger.error("Error loading system dashboard: #{e.message}")
        @jobs_status = { pending: 0, failed: 0, processed_today: 0 }
        @alerts = []
      end

      private

      def build_system_alerts
        alerts = []

        # Check failed jobs
        failed_jobs = SolidQueue::FailedExecution.count rescue 0
        if failed_jobs > 0
          alerts << {
            type: "error",
            title: "Failed Background Jobs",
            message: "#{failed_jobs} job(s) have failed and need attention"
          }
        end

        # Check error rate
        if @error_rate && @error_rate > 5
          alerts << {
            type: "warning",
            title: "High Error Rate",
            message: "Error rate is #{@error_rate}% in the last 24 hours"
          }
        end

        # Check queue depth
        if @queue_depth && @queue_depth > 100
          alerts << {
            type: "warning",
            title: "High Queue Depth",
            message: "#{@queue_depth} jobs waiting in queue"
          }
        end

        alerts
      end
    end
  end
end
