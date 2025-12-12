# frozen_string_literal: true

module Buyer
  class SavedSearchesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_saved_search, only: %i[show edit update destroy]

    def index
      authorize SavedSearch

      @saved_searches = policy_scope(current_user.saved_searches.order(created_at: :desc))
    end

    def show
      authorize @saved_search

      @matching_properties = @saved_search.matching_properties
                                          .includes(:user, hero_image_attachment: :blob)
                                          .limit(24)
      @new_count = @saved_search.new_matching_properties.count
    end

    def new
      authorize SavedSearch

      @saved_search = current_user.saved_searches.build(
        criteria: {},
        alert_frequency: "daily"
      )
    end

    def create
      authorize SavedSearch

      @saved_search = current_user.saved_searches.build(saved_search_params)

      if @saved_search.save
        redirect_to buyer_saved_search_path(@saved_search), notice: "Search saved successfully!"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @saved_search
    end

    def update
      authorize @saved_search

      if @saved_search.update(saved_search_params)
        redirect_to buyer_saved_search_path(@saved_search), notice: "Search updated successfully!"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @saved_search

      @saved_search.destroy
      redirect_to buyer_saved_searches_path, notice: "Search deleted."
    end

    private

    def set_saved_search
      @saved_search = current_user.saved_searches.find(params[:id])
    end

    def saved_search_params
      params.require(:saved_search).permit(
        :name,
        :email_alerts,
        :push_alerts,
        :alert_frequency,
        criteria: [
          :state,
          :min_price_cents,
          :max_price_cents,
          :min_bedrooms,
          :max_bedrooms,
          :min_bathrooms,
          :min_parking,
          { suburbs: [], postcodes: [], property_types: [], features: [] }
        ]
      )
    end
  end
end
