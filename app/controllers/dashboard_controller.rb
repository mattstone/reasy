# frozen_string_literal: true

class DashboardController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!

  def show
    @user = current_user
    authorize :dashboard, :show?
  end
end
