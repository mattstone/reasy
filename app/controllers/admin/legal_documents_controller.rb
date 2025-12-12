# frozen_string_literal: true

module Admin
  class LegalDocumentsController < Admin::BaseController
    before_action :set_legal_document, only: [:show, :edit, :update, :destroy, :publish, :preview]

    def index
      @legal_documents = LegalDocument.order(created_at: :desc)
      @pagy, @legal_documents = pagy(@legal_documents, items: 25)

      @current_terms = LegalDocument.current_terms
      @current_privacy = LegalDocument.current_privacy_policy
    end

    def show
    end

    def new
      @legal_document = LegalDocument.new
    end

    def create
      @legal_document = LegalDocument.new(legal_document_params)

      if @legal_document.save
        redirect_to admin_legal_document_path(@legal_document), notice: "Legal document created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @legal_document.update(legal_document_params)
        redirect_to admin_legal_document_path(@legal_document), notice: "Legal document updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @legal_document.destroy
      redirect_to admin_legal_documents_path, notice: "Legal document deleted."
    end

    def publish
      @legal_document.update!(published_at: Time.current, current: true)

      # Mark other documents of same type as not current
      LegalDocument.where(document_type: @legal_document.document_type)
                   .where.not(id: @legal_document.id)
                   .update_all(current: false)

      redirect_to admin_legal_document_path(@legal_document), notice: "Document published and set as current."
    end

    def preview
      render :preview, layout: "preview"
    end

    def history
      @legal_documents = LegalDocument.order(created_at: :desc)
      @grouped = @legal_documents.group_by(&:document_type)
    end

    private

    def set_legal_document
      @legal_document = LegalDocument.find(params[:id])
    end

    def legal_document_params
      params.require(:legal_document).permit(:title, :document_type, :content, :version)
    end
  end
end
