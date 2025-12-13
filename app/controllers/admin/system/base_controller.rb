# frozen_string_literal: true

module Admin
  module System
    class BaseController < Admin::BaseController
      layout "admin"

      private

      def metrics_service
        @metrics_service ||= Admin::SystemMetricsService.new
      end
    end
  end
end
