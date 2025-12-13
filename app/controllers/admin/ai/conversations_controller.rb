# frozen_string_literal: true

module Admin
  module AI
    class ConversationsController < Admin::BaseController
      before_action :set_conversation, only: [:show, :export]

      def index
        @conversations = ::AIConversation.order(created_at: :desc).includes(:user)

        @conversations = @conversations.where(assistant: params[:assistant]) if params[:assistant].present?
        @conversations = @conversations.where(user_id: params[:user_id]) if params[:user_id].present?

        @pagy, @conversations = pagy(@conversations, items: 25)

        # Stats
        @total_conversations = ::AIConversation.count
        @conversations_today = ::AIConversation.where("created_at >= ?", Date.current.beginning_of_day).count
        @conversations_this_week = ::AIConversation.where("created_at >= ?", 7.days.ago).count
        @assistant_breakdown = ::AIConversation.group(:assistant).count
      end

      def show
        @messages = @conversation.messages.order(created_at: :asc)
      end

      def export
        respond_to do |format|
          format.json do
            render json: {
              conversation: @conversation,
              messages: @conversation.messages.order(created_at: :asc)
            }
          end
        end
      end

      def export_all
        @conversations = ::AIConversation.includes(:messages).order(created_at: :desc).limit(1000)

        respond_to do |format|
          format.json do
            render json: @conversations.map { |c| { conversation: c, messages: c.messages } }
          end
        end
      end

      private

      def set_conversation
        @conversation = ::AIConversation.find(params[:id])
      end
    end
  end
end
