# frozen_string_literal: true

module Provider
  class JobsController < ApplicationController
    before_action :authenticate_user!
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped
    before_action :require_service_provider!
    before_action :set_job, only: [:show, :update]

    def index
      @jobs = current_provider_profile.provider_jobs.recent.includes(:client, :property)

      case params[:filter]
      when "pending"
        @jobs = @jobs.pending
      when "scheduled"
        @jobs = @jobs.scheduled
      when "in_progress"
        @jobs = @jobs.in_progress
      when "completed"
        @jobs = @jobs.completed
      when "active"
        @jobs = @jobs.active
      end

      @jobs = @jobs.by_service_type(params[:service_type]) if params[:service_type].present?

      @pagy, @jobs = pagy(@jobs, items: 20)

      # Stats
      @active_count = current_provider_profile.provider_jobs.active.count
      @completed_count = current_provider_profile.provider_jobs.completed.count
      @upcoming_count = current_provider_profile.provider_jobs.upcoming.count
    end

    def show
    end

    def update
      case params[:action_type]
      when "schedule"
        if params[:scheduled_date].present?
          @job.schedule!(Date.parse(params[:scheduled_date]))
          redirect_to provider_job_path(@job), notice: "Job scheduled."
        else
          redirect_to provider_job_path(@job), alert: "Please provide a scheduled date."
        end
      when "start"
        @job.start!
        redirect_to provider_job_path(@job), notice: "Job started."
      when "complete"
        @job.complete!(
          notes: params[:completion_notes],
          final_price_cents: params[:final_price_cents]
        )
        redirect_to provider_job_path(@job), notice: "Job completed."
      when "cancel"
        @job.cancel!
        redirect_to provider_jobs_path, notice: "Job cancelled."
      else
        if @job.update(job_params)
          redirect_to provider_job_path(@job), notice: "Job updated."
        else
          render :show, status: :unprocessable_entity
        end
      end
    end

    private

    def require_service_provider!
      unless current_user.service_provider? && current_provider_profile
        redirect_to dashboard_path, alert: "You need a service provider profile to access this area."
      end
    end

    def current_provider_profile
      @current_provider_profile ||= current_user.service_provider_profile
    end
    helper_method :current_provider_profile

    def set_job
      @job = current_provider_profile.provider_jobs.find(params[:id])
    end

    def job_params
      params.require(:provider_job).permit(:description, :quoted_price_cents, :scheduled_date)
    end
  end
end
