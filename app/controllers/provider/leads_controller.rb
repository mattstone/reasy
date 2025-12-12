# frozen_string_literal: true

module Provider
  class LeadsController < ApplicationController
    before_action :authenticate_user!
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped
    before_action :require_service_provider!
    before_action :set_lead, only: [:show, :update]

    def index
      @leads = current_provider_profile.provider_leads.recent.includes(:user, :property)

      case params[:filter]
      when "new"
        @leads = @leads.new_leads
      when "contacted"
        @leads = @leads.contacted
      when "quoted"
        @leads = @leads.quoted
      when "active"
        @leads = @leads.active
      when "closed"
        @leads = @leads.where(status: %w[accepted declined expired])
      end

      @leads = @leads.by_service_type(params[:service_type]) if params[:service_type].present?

      @pagy, @leads = pagy(@leads, items: 20)

      # Stats
      @new_count = current_provider_profile.provider_leads.new_leads.count
      @active_count = current_provider_profile.provider_leads.active.count
      @accepted_count = current_provider_profile.provider_leads.accepted.count
    end

    def show
    end

    def update
      case params[:action_type]
      when "contact"
        @lead.mark_contacted!
        redirect_to provider_lead_path(@lead), notice: "Lead marked as contacted."
      when "quote"
        @lead.mark_quoted!
        redirect_to provider_lead_path(@lead), notice: "Lead marked as quoted."
      when "accept"
        @lead.accept!
        create_job_from_lead(@lead) if params[:create_job]
        redirect_to provider_lead_path(@lead), notice: "Lead accepted."
      when "decline"
        @lead.decline!
        redirect_to provider_leads_path, notice: "Lead declined."
      else
        if @lead.update(lead_params)
          redirect_to provider_lead_path(@lead), notice: "Lead updated."
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

    def set_lead
      @lead = current_provider_profile.provider_leads.find(params[:id])
    end

    def lead_params
      params.require(:provider_lead).permit(:notes)
    end

    def create_job_from_lead(lead)
      current_provider_profile.provider_jobs.create!(
        provider_lead: lead,
        property: lead.property,
        client: lead.user,
        service_type: lead.service_type,
        title: "#{lead.service_type.humanize} Service",
        requirements: lead.requirements
      )
    end
  end
end
