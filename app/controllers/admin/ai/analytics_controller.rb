# frozen_string_literal: true

module Admin
  module AI
    class AnalyticsController < Admin::BaseController
      def show
        @total_conversations = AIConversation.count
        @total_messages = AIMessage.count
        @unique_users = AIConversation.distinct.count(:user_id)

        @conversations_by_assistant = AIConversation.group(:assistant).count
        @messages_this_week = AIMessage.where("created_at >= ?", 1.week.ago).count
        @messages_this_month = AIMessage.where("created_at >= ?", 1.month.ago).count

        @recent_activity = AIConversation.where("created_at >= ?", 30.days.ago)
                                         .group_by_day(:created_at)
                                         .count rescue {}

        @top_users = AIConversation.group(:user_id)
                                   .order("count_id DESC")
                                   .limit(10)
                                   .count(:id)
      end
    end
  end
end
