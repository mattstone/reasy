# frozen_string_literal: true

class NotificationsController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!
  before_action :set_notification, only: [:show, :mark_read]

  def index
    @notifications = policy_scope(Notification).recent
    @pagy, @notifications = pagy(@notifications, items: 25)

    @unread_count = policy_scope(Notification).unread.count
    @grouped_notifications = group_notifications(@notifications)
  end

  def show
    authorize @notification

    # Mark as read when viewing
    @notification.mark_read!

    # Redirect to action URL if present
    if @notification.action_url.present?
      redirect_to @notification.action_url
    else
      redirect_to notifications_path
    end
  end

  def mark_read
    authorize @notification

    @notification.mark_read!

    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.turbo_stream
    end
  end

  def mark_all_read
    authorize Notification, :mark_all_read?

    policy_scope(Notification).unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "All notifications marked as read." }
      format.turbo_stream
    end
  end

  private

  def set_notification
    @notification = Notification.find(params[:id])
  end

  def group_notifications(notifications)
    notifications.group_by do |notification|
      if notification.created_at.today?
        "Today"
      elsif notification.created_at.yesterday?
        "Yesterday"
      elsif notification.created_at > 7.days.ago
        "This Week"
      else
        "Earlier"
      end
    end
  end
end
