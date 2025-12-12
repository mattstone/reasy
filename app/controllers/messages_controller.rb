# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation

  def create
    @message = @conversation.messages.build(message_params)
    @message.sender = current_user
    @message.conversation = @conversation
    authorize @message

    if @conversation.send_message!(sender: current_user, content: message_params[:content])
      respond_to do |format|
        format.html { redirect_to @conversation }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @conversation, alert: "Failed to send message." }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message-form-error", partial: "messages/error") }
      end
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
