# frozen_string_literal: true

module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: [:show, :edit, :update, :impersonate, :suspend, :unsuspend, :activity, :ai_conversations]

    def index
      @users = User.order(created_at: :desc)

      # Filtering
      @users = @users.where(kyc_status: params[:kyc_status]) if params[:kyc_status].present?
      @users = @users.where("name ILIKE ? OR email ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?

      @pagy, @users = pagy(@users, items: 25)

      set_user_stats
    end

    def buyers
      @users = User.where("'buyer' = ANY(roles)").order(created_at: :desc)
      @pagy, @users = pagy(@users, items: 25)
      set_user_stats
      render :index
    end

    def sellers
      @users = User.where("'seller' = ANY(roles)").order(created_at: :desc)
      @pagy, @users = pagy(@users, items: 25)
      set_user_stats
      render :index
    end

    def providers
      @users = User.where("'service_provider' = ANY(roles)").order(created_at: :desc)
      @pagy, @users = pagy(@users, items: 25)
      set_user_stats
      render :index
    end

    def admins
      @users = User.where("'admin' = ANY(roles)").order(created_at: :desc)
      @pagy, @users = pagy(@users, items: 25)
      set_user_stats
      render :index
    end

    def show
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def impersonate
      session[:admin_user_id] = current_user.id
      sign_in(:user, @user)
      redirect_to dashboard_path, notice: "You are now impersonating #{@user.name}."
    end

    def stop_impersonating
      admin_user = User.find(session[:admin_user_id])
      session.delete(:admin_user_id)
      sign_in(:user, admin_user)
      redirect_to admin_users_path, notice: "Stopped impersonating."
    end

    def suspend
      @user.update!(suspended_at: Time.current)
      redirect_to admin_user_path(@user), notice: "User has been suspended."
    end

    def unsuspend
      @user.update!(suspended_at: nil)
      redirect_to admin_user_path(@user), notice: "User has been unsuspended."
    end

    def activity
      @audit_logs = AuditLog.where(user: @user).order(created_at: :desc).limit(50)
    end

    def ai_conversations
      @conversations = AiConversation.where(user: @user).order(created_at: :desc).limit(20)
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def set_user_stats
      @total_users = User.count
      @buyers_count = User.where("'buyer' = ANY(roles)").count
      @sellers_count = User.where("'seller' = ANY(roles)").count
      @providers_count = User.where("'service_provider' = ANY(roles)").count
    end

    def user_params
      params.require(:user).permit(:name, :email, :phone, :kyc_status, :subscription_status, roles: [])
    end
  end
end
