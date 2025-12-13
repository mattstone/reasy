# frozen_string_literal: true

class EntitiesController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!
  before_action :set_entity, only: %i[show edit update destroy make_default verify]

  def index
    @entities = policy_scope(current_user.entities)
  end

  def show
    authorize @entity
  end

  def new
    @entity = current_user.entities.build
    authorize @entity
  end

  def create
    @entity = current_user.entities.build(entity_params)
    authorize @entity

    if @entity.save
      redirect_to entities_path, notice: "Entity was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @entity
  end

  def update
    authorize @entity

    if @entity.update(entity_params)
      redirect_to entities_path, notice: "Entity was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @entity
    @entity.destroy

    redirect_to entities_path, notice: "Entity was successfully deleted."
  end

  def make_default
    authorize @entity, :update?
    @entity.make_default!

    redirect_to entities_path, notice: "#{@entity.display_name} is now your default entity."
  end

  def verify
    authorize @entity, :update?

    if @entity.update(verification_status: "submitted")
      redirect_to entities_path, notice: "Verification request submitted for #{@entity.display_name}."
    else
      redirect_to entities_path, alert: "Unable to submit verification request."
    end
  end

  private

  def set_entity
    @entity = current_user.entities.find(params[:id])
  end

  def entity_params
    params.require(:entity).permit(
      :entity_type,
      :name,
      :date_of_birth,
      :abn,
      :acn,
      :company_name,
      :fund_name,
      :fund_abn,
      :trustee_name,
      :trustee_type,
      :tfn,
      :address_line_1,
      :address_line_2,
      :suburb,
      :state,
      :postcode,
      :country,
      :is_default
    )
  end
end
