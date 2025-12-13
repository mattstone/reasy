# frozen_string_literal: true

module Admin
  module System
    class AIController < System::BaseController
      def show
        # Primary Metrics
        @total_conversations = AiConversation.count rescue 0
        @conversations_this_week = AiConversation.where("created_at >= ?", 1.week.ago).count rescue 0
        @avg_messages_per_conversation = calculate_avg_messages
        @avg_rating = calculate_avg_rating

        # Conversations by Assistant Type
        @by_assistant = AiConversation.group(:assistant_type).count rescue {}

        # Daily Volume Trend
        @daily_volume = AiConversation.where("created_at >= ?", 30.days.ago)
                                      .group_by_day(:created_at)
                                      .count rescue {}

        # Rating Distribution
        @rating_distribution = AiConversation.where.not(rating: nil)
                                             .group(:rating)
                                             .count rescue {}

        # Recent Conversations
        @recent_conversations = AiConversation.includes(:user)
                                              .order(created_at: :desc)
                                              .limit(10) rescue []

        # Response Time (if tracked)
        @avg_response_time = metrics_service.ai_avg_response_time
      end

      private

      def calculate_avg_messages
        total_conversations = AiConversation.count
        return 0 if total_conversations.zero?

        total_messages = AiMessage.count rescue 0
        (total_messages.to_f / total_conversations).round(1)
      rescue StandardError
        0
      end

      def calculate_avg_rating
        rated = AiConversation.where.not(rating: nil)
        return 0 if rated.empty?
        rated.average(:rating).to_f.round(2)
      rescue StandardError
        0
      end
    end
  end
end
