# frozen_string_literal: true

class ChecklistProgressController < ApplicationController
  layout "dashboard"

  before_action :set_checklist_item
  skip_after_action :verify_authorized, only: [:toggle]

  def toggle
    @progress = current_user.user_checklist_progresses.find_or_initialize_by(
      checklist_item: @checklist_item
    )

    if @progress.completed?
      @progress.reset!
      @completed = false
    else
      @progress.status = "pending" if @progress.new_record?
      @progress.save! if @progress.new_record?
      @progress.complete!
      @completed = true
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: dashboard_path }
    end
  end

  private

  def set_checklist_item
    @checklist_item = ChecklistItem.find(params[:id])
  end
end
