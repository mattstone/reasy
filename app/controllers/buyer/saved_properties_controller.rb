# frozen_string_literal: true

module Buyer
  class SavedPropertiesController < ApplicationController
    before_action :authenticate_user!
    skip_after_action :verify_policy_scoped, only: [:index]

    def index
      authorize PropertyLove

      @loved_properties = current_user.property_loves
                                      .includes(property: [:user, hero_image_attachment: :blob])
                                      .joins(:property)
                                      .where(properties: { status: "active" })
                                      .order(created_at: :desc)
    end

    def create
      @property = Property.active.find(params[:property_id])
      @love = current_user.property_loves.build(property: @property)

      authorize @love

      if @love.save
        respond_to do |format|
          format.html { redirect_back fallback_location: @property, notice: "Property saved!" }
          format.turbo_stream
        end
      else
        respond_to do |format|
          format.html { redirect_back fallback_location: @property, alert: "Could not save property." }
          format.turbo_stream { head :unprocessable_entity }
        end
      end
    end

    def destroy
      @love = current_user.property_loves.find(params[:id])
      @property = @love.property

      authorize @love

      @love.destroy

      respond_to do |format|
        format.html { redirect_back fallback_location: buyer_saved_properties_path, notice: "Property removed from saved." }
        format.turbo_stream
      end
    end
  end
end
