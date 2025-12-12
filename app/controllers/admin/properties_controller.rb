# frozen_string_literal: true

module Admin
  class PropertiesController < Admin::BaseController
    before_action :set_property, only: [:show, :edit, :update, :destroy, :approve, :reject, :feature, :unfeature]

    def index
      @properties = Property.order(created_at: :desc).includes(:user, hero_image_attachment: :blob)

      case params[:status]
      when "active"
        @properties = @properties.where(status: "active")
      when "pending"
        @properties = @properties.where(status: "pending")
      when "sold"
        @properties = @properties.where(status: "sold")
      end

      @properties = @properties.where("address ILIKE ?", "%#{params[:q]}%") if params[:q].present?

      @pagy, @properties = pagy(@properties, items: 25)

      # Stats
      @total_properties = Property.count
      @active_count = Property.where(status: "active").count
      @pending_count = Property.where(status: "pending").count
      @sold_count = Property.where(status: "sold").count
    end

    def pending
      @properties = Property.where(status: "pending").order(created_at: :desc).includes(:user)
      @pagy, @properties = pagy(@properties, items: 25)
      render :index
    end

    def reported
      @properties = Property.where(reported: true).order(created_at: :desc).includes(:user)
      @pagy, @properties = pagy(@properties, items: 25)
      render :index
    end

    def show
    end

    def edit
    end

    def update
      if @property.update(property_params)
        redirect_to admin_property_path(@property), notice: "Property updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @property.destroy
      redirect_to admin_properties_path, notice: "Property has been deleted."
    end

    def approve
      @property.update!(status: "active")
      redirect_to admin_property_path(@property), notice: "Property has been approved and is now active."
    end

    def reject
      @property.update!(status: "rejected")
      redirect_to admin_property_path(@property), notice: "Property has been rejected."
    end

    def feature
      @property.update!(featured: true)
      redirect_to admin_property_path(@property), notice: "Property is now featured."
    end

    def unfeature
      @property.update!(featured: false)
      redirect_to admin_property_path(@property), notice: "Property is no longer featured."
    end

    private

    def set_property
      @property = Property.find(params[:id])
    end

    def property_params
      params.require(:property).permit(:address, :suburb, :state, :postcode, :price_cents, :status, :property_type, :bedrooms, :bathrooms, :parking_spaces, :land_size_sqm, :floor_area_sqm, :description, :featured)
    end
  end
end
