# frozen_string_literal: true

class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: [:show]

  def index
    @conversations = policy_scope(Conversation)
                       .includes(:participants, :messages, :property)
                       .recent
    @pagy, @conversations = pagy(@conversations, items: 20)

    @unread_count = Conversation.with_unread_for(current_user).count
  end

  def show
    authorize @conversation

    # Mark as read when viewing
    @conversation.mark_read_for!(current_user)

    @messages = @conversation.messages.chronological.includes(:sender)
    @other_participants = @conversation.other_participants(current_user)
  end

  def create
    recipient = User.find(params[:recipient_id])
    property = params[:property_id].present? ? Property.find(params[:property_id]) : nil

    @conversation = Conversation.between(current_user, recipient, property: property)
    authorize @conversation

    # Send initial message if provided
    if params[:message].present?
      @conversation.send_message!(sender: current_user, content: params[:message])
    end

    redirect_to @conversation
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end
end
