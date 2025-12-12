# frozen_string_literal: true

module Admin
  class AuditLogsController < Admin::BaseController
    def index
      @audit_logs = AuditLog.order(created_at: :desc).includes(:user)

      @audit_logs = @audit_logs.where(action: params[:action_type]) if params[:action_type].present?
      @audit_logs = @audit_logs.where(user_id: params[:user_id]) if params[:user_id].present?

      if params[:date_from].present?
        @audit_logs = @audit_logs.where("created_at >= ?", Date.parse(params[:date_from]).beginning_of_day)
      end

      if params[:date_to].present?
        @audit_logs = @audit_logs.where("created_at <= ?", Date.parse(params[:date_to]).end_of_day)
      end

      @pagy, @audit_logs = pagy(@audit_logs, items: 50)
    end

    def show
      @audit_log = AuditLog.find(params[:id])
    end

    def export
      @audit_logs = AuditLog.order(created_at: :desc)

      respond_to do |format|
        format.csv do
          headers["Content-Disposition"] = "attachment; filename=\"audit_logs_#{Date.current}.csv\""
          headers["Content-Type"] = "text/csv"
        end
      end
    end
  end
end
