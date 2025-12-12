# frozen_string_literal: true

class Document < ApplicationRecord
  include SoftDeletable

  DOCUMENT_TYPES = %w[
    contract
    identification
    proof_of_funds
    pre_approval
    building_report
    pest_report
    strata_report
    title_search
    survey
    other
  ].freeze

  VISIBILITIES = %w[private shared public].freeze

  belongs_to :user
  belongs_to :documentable, polymorphic: true, optional: true

  has_one_attached :file

  validates :name, presence: true, length: { maximum: 255 }
  validates :document_type, inclusion: { in: DOCUMENT_TYPES }
  validates :visibility, inclusion: { in: VISIBILITIES }
  validates :file, presence: true, on: :create

  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(document_type: type) }
  scope :visible_to, ->(user) {
    where(user_id: user.id)
      .or(where(visibility: "public"))
      .or(where(visibility: "shared"))
  }

  def private?
    visibility == "private"
  end

  def shared?
    visibility == "shared"
  end

  def public?
    visibility == "public"
  end

  def file_size_display
    return "Unknown" unless file.attached?

    size = file.blob.byte_size
    if size < 1024
      "#{size} B"
    elsif size < 1024 * 1024
      "#{(size / 1024.0).round(1)} KB"
    else
      "#{(size / (1024.0 * 1024)).round(1)} MB"
    end
  end

  def file_extension
    return nil unless file.attached?

    File.extname(file.filename.to_s).delete(".").upcase
  end

  def document_type_display
    document_type.titleize.gsub("_", " ")
  end
end
