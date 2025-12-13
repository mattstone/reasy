# frozen_string_literal: true

module AI
  class ConversationsController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :set_conversation, only: %i[show message]

    def index
      authorize AIConversation

      @assistants = AI::AssistantService::ASSISTANTS
      @conversations = policy_scope(current_user.ai_conversations.recent)
      @conversations_by_assistant = @conversations.group_by(&:assistant)
    end

    def show
      authorize @conversation

      @messages = @conversation.ai_messages.chronological
      @assistant_info = AI::AssistantService::ASSISTANTS[@conversation.assistant.to_sym]
    end

    def create
      authorize AIConversation

      assistant_type = params[:assistant]

      unless AI::AssistantService::ASSISTANTS.key?(assistant_type&.to_sym)
        redirect_to ai_conversations_path, alert: "Invalid assistant type."
        return
      end

      service = AI::AssistantService.new(user: current_user, assistant_type: assistant_type)
      @conversation = service.start_conversation

      redirect_to ai_conversation_path(@conversation)
    end

    def message
      authorize @conversation, :update?

      content = params[:content]

      if content.blank?
        respond_to do |format|
          format.html { redirect_to ai_conversation_path(@conversation), alert: "Message cannot be blank." }
          format.turbo_stream { head :unprocessable_entity }
        end
        return
      end

      service = AI::AssistantService.new(
        user: current_user,
        assistant_type: @conversation.assistant,
        conversation: @conversation
      )

      result = service.chat(content)
      @user_message = @conversation.ai_messages.user_messages.order(created_at: :desc).first
      @assistant_message = result[:message]

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to ai_conversation_path(@conversation) }
      end
    end

    private

    def set_conversation
      @conversation = current_user.ai_conversations.find(params[:id])
    end
  end
end
