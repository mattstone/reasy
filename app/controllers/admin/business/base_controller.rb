# frozen_string_literal: true

module Admin
  module Business
    class BaseController < Admin::BaseController
      layout "admin"

      private

      def metrics_service
        @metrics_service ||= Admin::BusinessMetricsService.new
      end
    end
  end
end
