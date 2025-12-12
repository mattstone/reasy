# frozen_string_literal: true

class PropertiesController < ApplicationController
  skip_after_action :verify_authorized, only: [:index, :show, :search, :map]
  skip_after_action :verify_policy_scoped, only: [:index, :show, :search, :map]

  before_action :authenticate_user!, only: [:enquire, :love, :unlove]
  before_action :set_property, only: [:show, :enquire, :love, :unlove]

  def index
    @pagy, @properties = pagy(Property.active.includes(:user), limit: 12)
  end

  def show
    @property.record_view!(user: current_user) if current_user
  end

  def search
    @pagy, @properties = pagy(Property.active, limit: 12)
    render :index
  end

  def map
    scope = Property.active.where.not(latitude: nil, longitude: nil)

    # Apply filters
    scope = scope.where(property_type: params[:property_type]) if params[:property_type].present?
    scope = scope.where("bedrooms >= ?", params[:bedrooms]) if params[:bedrooms].present?

    if params[:price].present?
      min_price, max_price = params[:price].split("-").map { |p| p.present? ? p.to_i * 100 : nil }
      scope = scope.where("price_cents >= ?", min_price) if min_price
      scope = scope.where("price_cents <= ?", max_price) if max_price
    end

    @properties = scope.includes(:user, hero_image_attachment: :blob).limit(100)

    respond_to do |format|
      format.html
      format.json { render json: @properties.map { |p| property_map_data(p) } }
    end
  end

  def enquire
    authorize @property
    @enquiry = @property.enquiries.build(enquiry_params)
    @enquiry.buyer_profile = current_user.buyer_profile

    if @enquiry.save
      redirect_to @property, notice: "Your enquiry has been sent."
    else
      render :show
    end
  end

  def love
    authorize @property
    current_user.buyer_profile&.love_property(@property)
    respond_to do |format|
      format.html { redirect_back fallback_location: @property }
      format.turbo_stream
    end
  end

  def unlove
    authorize @property
    current_user.buyer_profile&.unlove_property(@property)
    respond_to do |format|
      format.html { redirect_back fallback_location: @property }
      format.turbo_stream
    end
  end

  private

  def set_property
    @property = Property.active.find(params[:id])
  end

  def search_params
    params.permit(:location, :min_price, :max_price, :bedrooms, :bathrooms, :property_type)
  end

  def enquiry_params
    params.require(:enquiry).permit(:message)
  end

  def property_map_data(property)
    {
      id: property.id,
      lat: property.latitude,
      lng: property.longitude,
      price: property.price_range_display,
      address: property.short_address,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      parking: property.parking_spaces,
      property_type: property.property_type,
      image_url: property.hero_image.attached? ? url_for(property.hero_image.variant(resize_to_fill: [200, 160])) : nil,
      url: property_path(property)
    }
  end
end
