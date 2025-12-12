# frozen_string_literal: true

class CoUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_relationship, only: [:show, :destroy]

  def index
    @relationships = policy_scope(CoUserRelationship).active.recent
    @pagy, @relationships = pagy(@relationships, items: 20)

    # Separate relationships where user is primary vs co-user
    @as_primary = @relationships.select { |r| r.primary_user_id == current_user.id }
    @as_co_user = @relationships.select { |r| r.co_user_id == current_user.id }
  end

  def show
    authorize @relationship, policy_class: CoUserPolicy
  end

  def destroy
    authorize @relationship, policy_class: CoUserPolicy

    if @relationship.revoke!
      redirect_to co_users_path, notice: "Co-user access has been revoked."
    else
      redirect_to co_users_path, alert: "Failed to revoke co-user access."
    end
  end

  def invitations
    authorize CoUserRelationship.new, :invitations?, policy_class: CoUserPolicy

    @pending_invitations = CoUserInvitation.where(inviter: current_user).pending.recent
    @received_invitations = CoUserInvitation.where(email: current_user.email.downcase).active.recent
  end

  private

  def set_relationship
    @relationship = CoUserRelationship.find(params[:id])
  end
end
