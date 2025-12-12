# frozen_string_literal: true

class ServiceProvidersController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  before_action :authenticate_user!, except: [:index, :show]

  def index
    @providers = ServiceProviderProfile.verified.accepting_clients.includes(:user)

    # Filter by service type
    if params[:service_type].present?
      @providers = @providers.by_service_type(params[:service_type])
    end

    # Filter by area
    if params[:area].present?
      @providers = @providers.by_area(params[:area])
    end

    # Search by name
    if params[:q].present?
      @providers = @providers.joins(:user).where(
        "service_provider_profiles.business_name ILIKE ? OR users.name ILIKE ?",
        "%#{params[:q]}%", "%#{params[:q]}%"
      )
    end

    # Sorting
    case params[:sort]
    when "rating"
      @providers = @providers.top_rated
    when "reviews"
      @providers = @providers.order(total_reviews: :desc)
    else
      # Featured first, then by rating
      @providers = @providers.order(featured: :desc, average_rating: :desc, total_reviews: :desc)
    end

    @pagy, @providers = pagy(@providers, items: 20)

    # Service types for filter
    @service_types = ServiceProviderProfile::SERVICE_TYPES
  end

  def show
    @provider = ServiceProviderProfile.verified.find(params[:id])
    @reviews = @provider.user.reviews_received.published.recent.limit(10)
  end
end
