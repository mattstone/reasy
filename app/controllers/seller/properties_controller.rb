# frozen_string_literal: true

module Seller
  class PropertiesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_property, only: %i[show edit update publish unpublish archive]

    WIZARD_STEPS = %w[address features description photos pricing entity intent preview].freeze

    def index
      authorize Property

      @tab = params[:tab]&.to_s || "all"
      @properties = policy_scope(current_user.properties)

      case @tab
      when "active"
        @properties = @properties.where(status: "active")
      when "draft"
        @properties = @properties.where(status: "draft")
      when "sold"
        @properties = @properties.where(status: "sold")
      when "archived"
        @properties = @properties.where(status: "archived")
      end

      @properties = @properties.order(updated_at: :desc)

      @counts = {
        all: current_user.properties.count,
        active: current_user.properties.where(status: "active").count,
        draft: current_user.properties.where(status: "draft").count,
        sold: current_user.properties.where(status: "sold").count,
        archived: current_user.properties.where(status: "archived").count
      }
    end

    def show
      authorize @property

      @offers = @property.offers.order(created_at: :desc).limit(5)
      @stats = {
        views: @property.view_count || 0,
        loves: @property.love_count || 0,
        enquiries: @property.property_enquiries.count,
        offers: @property.offers.count
      }
    end

    def new
      @property = current_user.properties.build(status: "draft")
      authorize @property

      @step = "address"
      @step_index = 1
      @entities = current_user.entities
    end

    def create
      @property = current_user.properties.build(property_params)
      @property.status = "draft"
      authorize @property

      if @property.save
        redirect_to edit_seller_property_path(@property, step: next_step("address")),
                    notice: "Property created. Continue adding details."
      else
        @step = "address"
        @step_index = 1
        @entities = current_user.entities
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @property

      @step = params[:step].presence || determine_current_step
      @step = "address" unless WIZARD_STEPS.include?(@step)
      @step_index = WIZARD_STEPS.index(@step) + 1
      @entities = current_user.entities
    end

    def update
      authorize @property

      @step = params[:step].presence || "address"

      if @property.update(property_params)
        if params[:commit] == "Save & Continue" && next_step(@step)
          redirect_to edit_seller_property_path(@property, step: next_step(@step)),
                      notice: "Progress saved."
        elsif params[:commit] == "Publish" && can_publish?
          @property.publish!
          redirect_to seller_property_path(@property), notice: "Property published successfully!"
        else
          redirect_to edit_seller_property_path(@property, step: @step),
                      notice: "Changes saved."
        end
      else
        @step_index = WIZARD_STEPS.index(@step) + 1
        @entities = current_user.entities
        render :edit, status: :unprocessable_entity
      end
    end

    def publish
      authorize @property, :update?

      if can_publish? && @property.publish!
        redirect_to seller_property_path(@property), notice: "Property is now live!"
      else
        redirect_to edit_seller_property_path(@property, step: "preview"),
                    alert: "Please complete all required fields before publishing."
      end
    end

    def unpublish
      authorize @property, :update?

      if @property.withdraw!
        redirect_to seller_property_path(@property), notice: "Property has been taken offline."
      else
        redirect_to seller_property_path(@property), alert: "Unable to unpublish this property."
      end
    end

    def archive
      authorize @property, :update?

      if @property.update(status: "archived")
        redirect_to seller_properties_path, notice: "Property has been archived."
      else
        redirect_to seller_property_path(@property), alert: "Unable to archive this property."
      end
    end

    private

    def set_property
      @property = current_user.properties.find(params[:id])
    end

    def property_params
      params.require(:property).permit(
        :listing_intent,
        :street_address,
        :unit_number,
        :suburb,
        :state,
        :postcode,
        :property_type,
        :bedrooms,
        :bathrooms,
        :parking_spaces,
        :land_size_sqm,
        :building_size_sqm,
        :headline,
        :description,
        :price_cents,
        :price,
        :price_display,
        :price_hidden,
        :entity_id,
        :hero_image,
        features: [],
        photos: [],
        floor_plans: []
      )
    end

    def next_step(current)
      current_index = WIZARD_STEPS.index(current)
      return nil if current_index.nil? || current_index >= WIZARD_STEPS.length - 1

      WIZARD_STEPS[current_index + 1]
    end

    def previous_step(current)
      current_index = WIZARD_STEPS.index(current)
      return nil if current_index.nil? || current_index <= 0

      WIZARD_STEPS[current_index - 1]
    end

    def determine_current_step
      return "features" if @property.street_address.blank?
      return "description" if @property.bedrooms.nil?
      return "photos" if @property.headline.blank?
      return "pricing" unless @property.photos.attached? || @property.hero_image.attached?
      return "entity" if @property.price_cents.nil? && @property.price_display.blank?
      return "intent" if @property.entity_id.nil?
      return "preview" if @property.listing_intent.blank?

      "preview"
    end

    def can_publish?
      @property.street_address.present? &&
        @property.suburb.present? &&
        @property.state.present? &&
        @property.postcode.present? &&
        @property.property_type.present? &&
        @property.listing_intent.present? &&
        (@property.price_cents.present? || @property.price_display.present? || @property.price_hidden?)
    end
  end
end
