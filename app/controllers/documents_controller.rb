# frozen_string_literal: true

class DocumentsController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!
  before_action :set_document, only: [:show, :destroy]

  def index
    @documents = policy_scope(Document).recent
    @pagy, @documents = pagy(@documents, items: 20)

    # Group by type for display
    @documents_by_type = @documents.group_by(&:document_type)

    # Filter by type if specified
    @documents = @documents.by_type(params[:type]) if params[:type].present?

    # Stats
    @total_documents = policy_scope(Document).count
    @document_types = Document::DOCUMENT_TYPES
  end

  def show
    authorize @document

    # If it's a downloadable request, redirect to the file
    if params[:download]
      redirect_to rails_blob_path(@document.file, disposition: "attachment")
    end
  end

  def create
    @document = Document.new(document_params)
    @document.user = current_user
    authorize @document

    if @document.save
      respond_to do |format|
        format.html { redirect_to documents_path, notice: "Document uploaded successfully." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to documents_path, alert: @document.errors.full_messages.join(", ") }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("upload-errors", partial: "upload_errors", locals: { document: @document }) }
      end
    end
  end

  def destroy
    authorize @document

    @document.destroy
    respond_to do |format|
      format.html { redirect_to documents_path, notice: "Document deleted." }
      format.turbo_stream
    end
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:name, :document_type, :visibility, :description, :file)
  end
end
