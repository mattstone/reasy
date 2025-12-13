# frozen_string_literal: true

class CoUserInvitationsController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!
  before_action :set_invitation, only: [:destroy, :resend, :revoke, :accept, :confirm]

  def new
    @invitation = CoUserInvitation.new
    authorize @invitation
  end

  def create
    @invitation = CoUserInvitation.new(invitation_params)
    @invitation.inviter = current_user
    authorize @invitation

    if @invitation.save
      # TODO: Send invitation email
      redirect_to co_users_invitations_path, notice: "Invitation sent to #{@invitation.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @invitation
    @invitation.destroy
    redirect_to co_users_invitations_path, notice: "Invitation cancelled."
  end

  def resend
    authorize @invitation

    if @invitation.resend!
      redirect_to co_users_invitations_path, notice: "Invitation resent to #{@invitation.email}."
    else
      redirect_to co_users_invitations_path, alert: "Failed to resend invitation."
    end
  end

  def revoke
    authorize @invitation

    if @invitation.revoke!
      redirect_to co_users_invitations_path, notice: "Invitation revoked."
    else
      redirect_to co_users_invitations_path, alert: "Failed to revoke invitation."
    end
  end

  def accept
    authorize @invitation

    if @invitation.expired?
      redirect_to dashboard_path, alert: "This invitation has expired."
    end
  end

  def confirm
    authorize @invitation

    if @invitation.accept!(current_user)
      redirect_to co_users_path, notice: "You've been added as a co-user!"
    else
      redirect_to dashboard_path, alert: "Failed to accept invitation."
    end
  end

  private

  def set_invitation
    @invitation = if params[:token]
      CoUserInvitation.find_by_token(params[:token])
    else
      CoUserInvitation.find(params[:id])
    end

    redirect_to dashboard_path, alert: "Invitation not found." unless @invitation
  end

  def invitation_params
    params.require(:co_user_invitation).permit(:email, :relationship, :personal_message)
  end
end
