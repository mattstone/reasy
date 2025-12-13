# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_13_040739) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_conversations", force: :cascade do |t|
    t.string "assistant", null: false
    t.bigint "context_id"
    t.string "context_type"
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.integer "message_count", default: 0, null: false
    t.jsonb "metadata", default: {}
    t.datetime "started_at", null: false
    t.integer "total_tokens", default: 0, null: false
    t.datetime "updated_at", null: false
    t.text "user_feedback"
    t.bigint "user_id", null: false
    t.integer "user_rating"
    t.index ["assistant"], name: "index_ai_conversations_on_assistant"
    t.index ["context_type", "context_id"], name: "index_ai_conversations_on_context_type_and_context_id"
    t.index ["started_at"], name: "index_ai_conversations_on_started_at"
    t.index ["user_id"], name: "index_ai_conversations_on_user_id"
    t.index ["user_rating"], name: "index_ai_conversations_on_user_rating"
  end

  create_table "ai_messages", force: :cascade do |t|
    t.bigint "ai_conversation_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "model_version"
    t.jsonb "prompt_context", default: {}
    t.integer "response_time_ms"
    t.string "role", null: false
    t.integer "tokens_used"
    t.index ["ai_conversation_id"], name: "index_ai_messages_on_ai_conversation_id"
    t.index ["created_at"], name: "index_ai_messages_on_created_at"
    t.index ["role"], name: "index_ai_messages_on_role"
  end

  create_table "ai_voice_settings", force: :cascade do |t|
    t.string "assistant", null: false
    t.datetime "created_at", null: false
    t.integer "detail_level", default: 5, null: false
    t.string "name", null: false
    t.text "personality_description", null: false
    t.string "restricted_topics", default: [], array: true
    t.string "role", null: false
    t.text "sample_greeting"
    t.integer "tone_level", default: 5, null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.integer "warmth_level", default: 7, null: false
    t.index ["assistant"], name: "index_ai_voice_settings_on_assistant", unique: true
    t.index ["updated_by_id"], name: "index_ai_voice_settings_on_updated_by_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action_type", null: false
    t.datetime "created_at", null: false
    t.bigint "impersonated_by_id"
    t.string "ip_address"
    t.jsonb "metadata", default: {}
    t.jsonb "recorded_changes", default: {}
    t.string "request_id"
    t.bigint "resource_id", null: false
    t.string "resource_type", null: false
    t.string "session_id"
    t.text "user_agent"
    t.bigint "user_id"
    t.index ["action_type"], name: "index_audit_logs_on_action_type"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["impersonated_by_id"], name: "index_audit_logs_on_impersonated_by_id"
    t.index ["request_id"], name: "index_audit_logs_on_request_id"
    t.index ["resource_type", "resource_id"], name: "index_audit_logs_on_resource_type_and_resource_id"
    t.index ["session_id"], name: "index_audit_logs_on_session_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "buyer_profiles", force: :cascade do |t|
    t.integer "bathrooms_min"
    t.integer "bedrooms_min"
    t.string "budget_currency", default: "AUD"
    t.integer "budget_max_cents"
    t.integer "budget_min_cents"
    t.string "buying_timeline"
    t.datetime "created_at", null: false
    t.bigint "default_entity_id"
    t.datetime "deleted_at"
    t.string "finance_status", default: "exploring"
    t.boolean "first_home_buyer", default: false
    t.jsonb "location_preferences", default: {}
    t.string "must_have_features", default: [], array: true
    t.string "nice_to_have_features", default: [], array: true
    t.integer "parking_min"
    t.integer "pre_approval_amount_cents"
    t.date "pre_approval_expires_at"
    t.string "pre_approval_lender"
    t.string "property_types", default: [], array: true
    t.string "search_areas", default: [], array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["default_entity_id"], name: "index_buyer_profiles_on_default_entity_id"
    t.index ["deleted_at"], name: "index_buyer_profiles_on_deleted_at"
    t.index ["finance_status"], name: "index_buyer_profiles_on_finance_status"
    t.index ["must_have_features"], name: "index_buyer_profiles_on_must_have_features", using: :gin
    t.index ["property_types"], name: "index_buyer_profiles_on_property_types", using: :gin
    t.index ["search_areas"], name: "index_buyer_profiles_on_search_areas", using: :gin
    t.index ["user_id"], name: "index_buyer_profiles_on_user_id", unique: true
  end

  create_table "co_user_invitations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_expires_at"
    t.datetime "invitation_sent_at"
    t.string "invitation_token", null: false
    t.bigint "invitee_id"
    t.bigint "inviter_id", null: false
    t.string "name"
    t.string "relationship"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_co_user_invitations_on_email"
    t.index ["invitation_token"], name: "index_co_user_invitations_on_invitation_token", unique: true
    t.index ["invitee_id"], name: "index_co_user_invitations_on_invitee_id"
    t.index ["inviter_id"], name: "index_co_user_invitations_on_inviter_id"
    t.index ["status"], name: "index_co_user_invitations_on_status"
  end

  create_table "co_user_relationships", force: :cascade do |t|
    t.boolean "can_make_offers", default: false
    t.boolean "can_schedule_viewings", default: false
    t.boolean "can_send_messages", default: true
    t.boolean "can_view_listings", default: true
    t.boolean "can_view_offers", default: true
    t.bigint "co_user_id", null: false
    t.bigint "co_user_invitation_id"
    t.datetime "created_at", null: false
    t.bigint "primary_user_id", null: false
    t.string "relationship"
    t.string "status", default: "active", null: false
    t.string "stripe_subscription_id"
    t.datetime "subscription_ends_at"
    t.datetime "subscription_started_at"
    t.string "subscription_status", default: "trial"
    t.datetime "updated_at", null: false
    t.index ["co_user_id"], name: "index_co_user_relationships_on_co_user_id"
    t.index ["co_user_invitation_id"], name: "index_co_user_relationships_on_co_user_invitation_id"
    t.index ["primary_user_id", "co_user_id"], name: "idx_co_user_unique_pair", unique: true
    t.index ["primary_user_id"], name: "index_co_user_relationships_on_primary_user_id"
    t.index ["status"], name: "index_co_user_relationships_on_status"
  end

  create_table "conversation_participants", force: :cascade do |t|
    t.boolean "archived", default: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_read_at"
    t.boolean "muted", default: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conversation_id", "user_id"], name: "idx_conv_participants_unique", unique: true
    t.index ["conversation_id"], name: "index_conversation_participants_on_conversation_id"
    t.index ["user_id"], name: "index_conversation_participants_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_message_at"
    t.integer "message_count", default: 0
    t.bigint "property_id"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_conversations_on_property_id"
  end

  create_table "entities", force: :cascade do |t|
    t.string "abn"
    t.string "acn"
    t.string "company_name"
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.datetime "deleted_at"
    t.string "director_names", default: [], array: true
    t.string "email"
    t.string "entity_type", null: false
    t.string "fund_abn"
    t.string "fund_name"
    t.boolean "is_default", default: false, null: false
    t.string "name", null: false
    t.string "phone"
    t.text "registered_address"
    t.string "tfn_bidx"
    t.text "tfn_ciphertext"
    t.datetime "trust_deed_verified_at"
    t.string "trustee_names", default: [], array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.text "verification_notes"
    t.string "verification_status", default: "pending", null: false
    t.datetime "verified_at"
    t.index ["abn"], name: "index_entities_on_abn", unique: true, where: "((abn IS NOT NULL) AND (deleted_at IS NULL))"
    t.index ["acn"], name: "index_entities_on_acn", unique: true, where: "((acn IS NOT NULL) AND (deleted_at IS NULL))"
    t.index ["deleted_at"], name: "index_entities_on_deleted_at"
    t.index ["entity_type"], name: "index_entities_on_entity_type"
    t.index ["fund_abn"], name: "index_entities_on_fund_abn", unique: true, where: "((fund_abn IS NOT NULL) AND (deleted_at IS NULL))"
    t.index ["is_default"], name: "index_entities_on_is_default"
    t.index ["tfn_bidx"], name: "index_entities_on_tfn_bidx", unique: true, where: "((tfn_bidx IS NOT NULL) AND (deleted_at IS NULL))"
    t.index ["user_id", "is_default"], name: "index_entities_on_user_id_and_is_default", where: "((is_default = true) AND (deleted_at IS NULL))"
    t.index ["user_id"], name: "index_entities_on_user_id"
    t.index ["verification_status"], name: "index_entities_on_verification_status"
  end

  create_table "legal_document_acceptances", force: :cascade do |t|
    t.datetime "accepted_at", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.bigint "legal_document_id", null: false
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.bigint "user_id", null: false
    t.index ["legal_document_id"], name: "index_legal_document_acceptances_on_legal_document_id"
    t.index ["user_id", "legal_document_id"], name: "idx_legal_acceptances_user_document", unique: true
    t.index ["user_id"], name: "index_legal_document_acceptances_on_user_id"
  end

  create_table "legal_documents", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "document_type", null: false
    t.boolean "is_current", default: false, null: false
    t.boolean "is_draft", default: true, null: false
    t.datetime "published_at"
    t.bigint "published_by_id"
    t.boolean "requires_acceptance", default: true, null: false
    t.text "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.index ["created_by_id"], name: "index_legal_documents_on_created_by_id"
    t.index ["document_type", "is_current"], name: "index_legal_documents_on_document_type_and_is_current", where: "(is_current = true)"
    t.index ["document_type", "version"], name: "index_legal_documents_on_document_type_and_version", unique: true
    t.index ["published_at"], name: "index_legal_documents_on_published_at"
    t.index ["published_by_id"], name: "index_legal_documents_on_published_by_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "edited_at"
    t.string "message_type", default: "text"
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
    t.index ["deleted_at"], name: "index_messages_on_deleted_at"
    t.index ["message_type"], name: "index_messages_on_message_type"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "action_text"
    t.string "action_url"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "email_sent_at"
    t.jsonb "metadata", default: {}
    t.bigint "notifiable_id"
    t.string "notifiable_type"
    t.string "notification_type", null: false
    t.datetime "push_sent_at"
    t.datetime "read_at"
    t.boolean "send_email", default: true
    t.boolean "send_push", default: true
    t.boolean "send_sms", default: false
    t.datetime "sms_sent_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["read_at"], name: "index_notifications_on_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "offers", force: :cascade do |t|
    t.datetime "accepted_at"
    t.integer "amount_cents", null: false
    t.bigint "buyer_entity_id"
    t.bigint "buyer_id", null: false
    t.datetime "cooling_off_ends_at"
    t.boolean "cooling_off_waived", default: false
    t.bigint "counter_offer_id"
    t.datetime "created_at", null: false
    t.string "currency", default: "AUD"
    t.datetime "deleted_at"
    t.integer "deposit_cents"
    t.integer "deposit_percentage"
    t.datetime "expires_at"
    t.string "finance_lender"
    t.string "finance_type", null: false
    t.text "other_conditions"
    t.bigint "property_id", null: false
    t.date "proposed_settlement_date"
    t.datetime "rejected_at"
    t.datetime "responded_at"
    t.text "seller_response"
    t.integer "settlement_days", null: false
    t.string "status", default: "draft", null: false
    t.boolean "subject_to_building_inspection", default: false
    t.boolean "subject_to_finance", default: false
    t.boolean "subject_to_pest_inspection", default: false
    t.boolean "subject_to_sale_of_property", default: false
    t.boolean "subject_to_valuation", default: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.datetime "viewed_at"
    t.datetime "withdrawn_at"
    t.index ["buyer_entity_id"], name: "index_offers_on_buyer_entity_id"
    t.index ["buyer_id"], name: "index_offers_on_buyer_id"
    t.index ["counter_offer_id"], name: "index_offers_on_counter_offer_id"
    t.index ["deleted_at"], name: "index_offers_on_deleted_at"
    t.index ["expires_at"], name: "index_offers_on_expires_at"
    t.index ["finance_type"], name: "index_offers_on_finance_type"
    t.index ["property_id"], name: "index_offers_on_property_id"
    t.index ["status"], name: "index_offers_on_status"
    t.index ["submitted_at"], name: "index_offers_on_submitted_at"
  end

  create_table "postcode_profiles", force: :cascade do |t|
    t.decimal "avg_household_size"
    t.datetime "created_at", null: false
    t.string "data_source"
    t.integer "data_year"
    t.decimal "families_with_children_pct"
    t.datetime "last_updated_at"
    t.decimal "latitude"
    t.string "locality"
    t.decimal "longitude"
    t.integer "median_age"
    t.bigint "median_house_price_cents"
    t.bigint "median_household_income_cents"
    t.bigint "median_land_value_cents"
    t.bigint "median_unit_price_cents"
    t.decimal "mortgage_pct"
    t.decimal "owner_occupied_pct"
    t.integer "population"
    t.string "postcode"
    t.decimal "professional_occupation_pct"
    t.decimal "rented_pct"
    t.integer "seifa_advantage_disadvantage"
    t.integer "seifa_economic_resources"
    t.integer "seifa_education_occupation"
    t.string "state"
    t.decimal "unemployment_rate"
    t.decimal "university_educated_pct"
    t.datetime "updated_at", null: false
    t.index ["latitude", "longitude"], name: "index_postcode_profiles_on_latitude_and_longitude"
    t.index ["postcode"], name: "index_postcode_profiles_on_postcode", unique: true
    t.index ["state"], name: "index_postcode_profiles_on_state"
  end

  create_table "properties", force: :cascade do |t|
    t.text "ai_generated_description"
    t.integer "bathrooms"
    t.integer "bedrooms"
    t.integer "building_size_sqm"
    t.string "country", default: "Australia"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.integer "enquiry_count", default: 0
    t.bigint "entity_id"
    t.datetime "estimated_value_at"
    t.integer "estimated_value_cents"
    t.string "features", default: [], array: true
    t.string "headline"
    t.integer "land_size_sqm"
    t.decimal "latitude", precision: 10, scale: 8
    t.string "listing_intent", default: "want_to_sell", null: false
    t.decimal "longitude", precision: 11, scale: 8
    t.integer "love_count", default: 0
    t.integer "offer_count", default: 0
    t.string "ownership_verification_method"
    t.boolean "ownership_verified", default: false
    t.datetime "ownership_verified_at"
    t.integer "parking_spaces"
    t.string "postcode", null: false
    t.integer "price_cents"
    t.string "price_display"
    t.boolean "price_hidden", default: false
    t.integer "price_max_cents"
    t.integer "price_min_cents"
    t.string "property_type", null: false
    t.datetime "published_at"
    t.datetime "sold_at"
    t.string "state", null: false
    t.string "status", default: "draft", null: false
    t.string "street_address", null: false
    t.string "suburb", null: false
    t.datetime "under_offer_at"
    t.string "unit_number"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "valuation_source"
    t.integer "view_count", default: 0
    t.datetime "withdrawn_at"
    t.integer "year_built"
    t.index ["bedrooms"], name: "index_properties_on_bedrooms"
    t.index ["deleted_at"], name: "index_properties_on_deleted_at"
    t.index ["entity_id"], name: "index_properties_on_entity_id"
    t.index ["features"], name: "index_properties_on_features", using: :gin
    t.index ["latitude", "longitude"], name: "index_properties_on_latitude_and_longitude"
    t.index ["listing_intent"], name: "index_properties_on_listing_intent"
    t.index ["postcode"], name: "index_properties_on_postcode"
    t.index ["price_cents"], name: "index_properties_on_price_cents"
    t.index ["property_type"], name: "index_properties_on_property_type"
    t.index ["published_at"], name: "index_properties_on_published_at"
    t.index ["state"], name: "index_properties_on_state"
    t.index ["status"], name: "index_properties_on_status"
    t.index ["suburb"], name: "index_properties_on_suburb"
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "property_documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "document_type", null: false
    t.bigint "property_id", null: false
    t.boolean "requires_nda", default: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id", null: false
    t.boolean "visible_to_buyers", default: true
    t.index ["deleted_at"], name: "index_property_documents_on_deleted_at"
    t.index ["document_type"], name: "index_property_documents_on_document_type"
    t.index ["property_id"], name: "index_property_documents_on_property_id"
    t.index ["uploaded_by_id"], name: "index_property_documents_on_uploaded_by_id"
    t.index ["visible_to_buyers"], name: "index_property_documents_on_visible_to_buyers"
  end

  create_table "property_enquiries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "entity_id"
    t.text "message", null: false
    t.bigint "property_id", null: false
    t.datetime "responded_at"
    t.text "response"
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["entity_id"], name: "index_property_enquiries_on_entity_id"
    t.index ["property_id"], name: "index_property_enquiries_on_property_id"
    t.index ["status"], name: "index_property_enquiries_on_status"
    t.index ["user_id"], name: "index_property_enquiries_on_user_id"
  end

  create_table "property_loves", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "property_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["property_id"], name: "index_property_loves_on_property_id"
    t.index ["user_id", "property_id"], name: "index_property_loves_on_user_id_and_property_id", unique: true
    t.index ["user_id"], name: "index_property_loves_on_user_id"
  end

  create_table "property_sales", force: :cascade do |t|
    t.string "address"
    t.integer "bathrooms"
    t.integer "bedrooms"
    t.decimal "building_area_sqm"
    t.date "contract_date"
    t.datetime "created_at", null: false
    t.string "data_source"
    t.decimal "land_area_sqm"
    t.bigint "land_value_cents"
    t.date "land_value_date"
    t.decimal "latitude"
    t.decimal "longitude"
    t.integer "parking"
    t.string "postcode"
    t.string "property_id"
    t.string "property_type"
    t.bigint "sale_price_cents"
    t.date "settlement_date"
    t.string "source_id"
    t.string "state"
    t.boolean "strata_lot"
    t.string "street_name"
    t.string "street_number"
    t.string "suburb"
    t.string "unit_number"
    t.datetime "updated_at", null: false
    t.integer "year_built"
    t.string "zoning"
    t.index ["contract_date"], name: "index_property_sales_on_contract_date"
    t.index ["latitude", "longitude"], name: "index_property_sales_on_latitude_and_longitude"
    t.index ["postcode"], name: "index_property_sales_on_postcode"
    t.index ["property_id"], name: "index_property_sales_on_property_id"
    t.index ["property_type"], name: "index_property_sales_on_property_type"
    t.index ["source_id"], name: "index_property_sales_on_source_id", unique: true
    t.index ["state"], name: "index_property_sales_on_state"
    t.index ["suburb"], name: "index_property_sales_on_suburb"
  end

  create_table "property_views", force: :cascade do |t|
    t.string "ip_address"
    t.bigint "property_id", null: false
    t.string "referrer"
    t.text "user_agent"
    t.bigint "user_id"
    t.datetime "viewed_at", null: false
    t.index ["property_id"], name: "index_property_views_on_property_id"
    t.index ["user_id"], name: "index_property_views_on_user_id"
    t.index ["viewed_at"], name: "index_property_views_on_viewed_at"
  end

  create_table "provider_jobs", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.integer "client_rating"
    t.text "client_review"
    t.datetime "completed_at"
    t.text "completion_notes"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "final_price_cents"
    t.bigint "property_id"
    t.bigint "provider_lead_id"
    t.integer "quoted_price_cents"
    t.text "requirements"
    t.date "scheduled_date"
    t.bigint "service_provider_profile_id", null: false
    t.string "service_type", null: false
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.bigint "transaction_id"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_provider_jobs_on_client_id"
    t.index ["property_id"], name: "index_provider_jobs_on_property_id"
    t.index ["provider_lead_id"], name: "index_provider_jobs_on_provider_lead_id"
    t.index ["scheduled_date"], name: "index_provider_jobs_on_scheduled_date"
    t.index ["service_provider_profile_id"], name: "index_provider_jobs_on_service_provider_profile_id"
    t.index ["service_type"], name: "index_provider_jobs_on_service_type"
    t.index ["status"], name: "index_provider_jobs_on_status"
    t.index ["transaction_id"], name: "index_provider_jobs_on_transaction_id"
  end

  create_table "provider_leads", force: :cascade do |t|
    t.datetime "contacted_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.text "notes"
    t.integer "priority", default: 0
    t.bigint "property_id"
    t.text "requirements"
    t.bigint "service_provider_profile_id", null: false
    t.string "service_type", null: false
    t.string "source", default: "platform"
    t.string "status", default: "new", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_provider_leads_on_expires_at"
    t.index ["property_id"], name: "index_provider_leads_on_property_id"
    t.index ["service_provider_profile_id"], name: "index_provider_leads_on_service_provider_profile_id"
    t.index ["service_type"], name: "index_provider_leads_on_service_type"
    t.index ["status"], name: "index_provider_leads_on_status"
    t.index ["user_id"], name: "index_provider_leads_on_user_id"
  end

  create_table "review_disputes", force: :cascade do |t|
    t.text "admin_notes"
    t.datetime "created_at", null: false
    t.bigint "disputed_by_id", null: false
    t.jsonb "evidence", default: []
    t.text "explanation", null: false
    t.string "reason", null: false
    t.text "resolution_notes"
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.bigint "review_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["disputed_by_id"], name: "index_review_disputes_on_disputed_by_id"
    t.index ["reason"], name: "index_review_disputes_on_reason"
    t.index ["resolved_by_id"], name: "index_review_disputes_on_resolved_by_id"
    t.index ["review_id"], name: "index_review_disputes_on_review_id"
    t.index ["status"], name: "index_review_disputes_on_status"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "admin_notes"
    t.text "body", null: false
    t.jsonb "category_ratings", default: {}
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "hold_reason"
    t.datetime "hold_until"
    t.integer "overall_rating", null: false
    t.text "public_response"
    t.datetime "public_response_at"
    t.bigint "reviewee_id", null: false
    t.string "reviewee_role", null: false
    t.bigint "reviewer_id", null: false
    t.string "status", default: "pending", null: false
    t.string "title"
    t.bigint "transaction_id"
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_reviews_on_deleted_at"
    t.index ["hold_until"], name: "index_reviews_on_hold_until"
    t.index ["overall_rating"], name: "index_reviews_on_overall_rating"
    t.index ["reviewee_id", "reviewee_role"], name: "index_reviews_on_reviewee_id_and_reviewee_role"
    t.index ["reviewee_id"], name: "index_reviews_on_reviewee_id"
    t.index ["reviewee_role"], name: "index_reviews_on_reviewee_role"
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
    t.index ["status"], name: "index_reviews_on_status"
    t.index ["transaction_id"], name: "index_reviews_on_transaction_id"
  end

  create_table "saved_searches", force: :cascade do |t|
    t.string "alert_frequency", default: "instant"
    t.datetime "created_at", null: false
    t.jsonb "criteria", default: {}, null: false
    t.boolean "email_alerts", default: true
    t.datetime "last_alerted_at"
    t.string "name", null: false
    t.boolean "push_alerts", default: true
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["alert_frequency"], name: "index_saved_searches_on_alert_frequency"
    t.index ["user_id"], name: "index_saved_searches_on_user_id"
  end

  create_table "seller_profiles", force: :cascade do |t|
    t.boolean "accept_cash_buyers", default: true
    t.boolean "accept_finance_buyers", default: true
    t.boolean "accept_pre_approved_buyers", default: true
    t.boolean "allow_direct_contact", default: true
    t.boolean "allow_scheduled_viewings", default: true
    t.datetime "created_at", null: false
    t.bigint "default_entity_id"
    t.datetime "deleted_at"
    t.string "preferred_contact_method", default: "platform"
    t.string "preferred_settlement_period", default: "standard"
    t.date "specific_settlement_date"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.jsonb "viewing_availability", default: {}
    t.index ["default_entity_id"], name: "index_seller_profiles_on_default_entity_id"
    t.index ["deleted_at"], name: "index_seller_profiles_on_deleted_at"
    t.index ["preferred_settlement_period"], name: "index_seller_profiles_on_preferred_settlement_period"
    t.index ["user_id"], name: "index_seller_profiles_on_user_id", unique: true
  end

  create_table "service_provider_profiles", force: :cascade do |t|
    t.string "abn"
    t.boolean "accepting_new_clients", default: true
    t.jsonb "availability", default: {}
    t.decimal "average_rating", precision: 3, scale: 2
    t.text "business_address"
    t.string "business_email"
    t.string "business_name", null: false
    t.string "business_phone"
    t.datetime "created_at", null: false
    t.jsonb "credentials", default: []
    t.datetime "deleted_at"
    t.text "description"
    t.string "differentiators", default: [], array: true
    t.boolean "featured", default: false
    t.datetime "featured_until"
    t.text "guarantee_statement"
    t.string "headline"
    t.jsonb "pricing", default: {}
    t.string "professional_indemnity_amount"
    t.string "profile_photo_url"
    t.string "public_liability_amount"
    t.string "response_time_commitment"
    t.string "service_areas", default: [], array: true
    t.string "service_type", null: false
    t.integer "total_jobs_completed", default: 0
    t.integer "total_reviews", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.text "verification_notes"
    t.string "verification_status", default: "pending"
    t.datetime "verified_at"
    t.index ["abn"], name: "index_service_provider_profiles_on_abn", unique: true, where: "((abn IS NOT NULL) AND (deleted_at IS NULL))"
    t.index ["accepting_new_clients"], name: "index_service_provider_profiles_on_accepting_new_clients"
    t.index ["average_rating", "total_reviews"], name: "idx_on_average_rating_total_reviews_fa1b09efc5"
    t.index ["deleted_at"], name: "index_service_provider_profiles_on_deleted_at"
    t.index ["featured"], name: "index_service_provider_profiles_on_featured"
    t.index ["service_areas"], name: "index_service_provider_profiles_on_service_areas", using: :gin
    t.index ["service_type"], name: "index_service_provider_profiles_on_service_type"
    t.index ["user_id"], name: "index_service_provider_profiles_on_user_id", unique: true
    t.index ["verification_status"], name: "index_service_provider_profiles_on_verification_status"
  end

  create_table "suburb_profiles", force: :cascade do |t|
    t.decimal "avg_household_size"
    t.datetime "created_at", null: false
    t.integer "data_year"
    t.integer "days_on_market_house"
    t.integer "days_on_market_unit"
    t.decimal "house_price_growth_1yr"
    t.decimal "house_price_growth_5yr"
    t.datetime "last_updated_at"
    t.decimal "latitude"
    t.decimal "longitude"
    t.integer "median_age"
    t.bigint "median_house_price_cents"
    t.bigint "median_household_income_cents"
    t.bigint "median_land_value_cents"
    t.bigint "median_unit_price_cents"
    t.decimal "owner_occupied_pct"
    t.integer "population"
    t.string "postcode"
    t.decimal "rental_yield_house"
    t.decimal "rental_yield_unit"
    t.decimal "rented_pct"
    t.integer "sales_volume_12m"
    t.string "school_catchment_primary"
    t.string "school_catchment_secondary"
    t.integer "seifa_score"
    t.string "state"
    t.string "suburb"
    t.decimal "unit_price_growth_1yr"
    t.decimal "unit_price_growth_5yr"
    t.datetime "updated_at", null: false
    t.index ["latitude", "longitude"], name: "index_suburb_profiles_on_latitude_and_longitude"
    t.index ["postcode"], name: "index_suburb_profiles_on_postcode"
    t.index ["state"], name: "index_suburb_profiles_on_state"
    t.index ["suburb", "state"], name: "index_suburb_profiles_on_suburb_and_state", unique: true
  end

  create_table "transaction_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}
    t.datetime "occurred_at", null: false
    t.string "title", null: false
    t.bigint "transaction_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["event_type"], name: "index_transaction_events_on_event_type"
    t.index ["occurred_at"], name: "index_transaction_events_on_occurred_at"
    t.index ["transaction_id"], name: "index_transaction_events_on_transaction_id"
    t.index ["user_id"], name: "index_transaction_events_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.datetime "building_inspection_at"
    t.boolean "building_inspection_passed", default: false
    t.bigint "buyer_conveyancer_id"
    t.bigint "buyer_entity_id"
    t.bigint "buyer_id", null: false
    t.datetime "conditions_due_at"
    t.datetime "cooling_off_ends_at"
    t.datetime "created_at", null: false
    t.integer "deposit_cents"
    t.integer "deposit_paid_cents", default: 0
    t.date "exchange_date"
    t.datetime "fallen_through_at"
    t.text "fallen_through_reason"
    t.boolean "finance_approved", default: false
    t.datetime "finance_approved_at"
    t.bigint "offer_id", null: false
    t.datetime "pest_inspection_at"
    t.boolean "pest_inspection_passed", default: false
    t.bigint "property_id", null: false
    t.integer "sale_price_cents", null: false
    t.bigint "seller_conveyancer_id"
    t.bigint "seller_entity_id"
    t.bigint "seller_id", null: false
    t.datetime "settled_at"
    t.date "settlement_date"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_conveyancer_id"], name: "index_transactions_on_buyer_conveyancer_id"
    t.index ["buyer_entity_id"], name: "index_transactions_on_buyer_entity_id"
    t.index ["buyer_id"], name: "index_transactions_on_buyer_id"
    t.index ["exchange_date"], name: "index_transactions_on_exchange_date"
    t.index ["offer_id"], name: "index_transactions_on_offer_id"
    t.index ["property_id"], name: "index_transactions_on_property_id"
    t.index ["seller_conveyancer_id"], name: "index_transactions_on_seller_conveyancer_id"
    t.index ["seller_entity_id"], name: "index_transactions_on_seller_entity_id"
    t.index ["seller_id"], name: "index_transactions_on_seller_id"
    t.index ["settled_at"], name: "index_transactions_on_settled_at"
    t.index ["settlement_date"], name: "index_transactions_on_settlement_date"
    t.index ["status"], name: "index_transactions_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.datetime "deleted_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "kyc_status", default: "pending", null: false
    t.string "kyc_verification_id"
    t.datetime "kyc_verified_at"
    t.string "last_privacy_version_accepted"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "last_terms_version_accepted"
    t.datetime "locked_at"
    t.string "name", null: false
    t.jsonb "notification_preferences", default: {}
    t.datetime "onboarding_completed_at"
    t.string "phone"
    t.string "phone_country_code", default: "AU"
    t.string "preferred_language", default: "en"
    t.datetime "privacy_policy_accepted_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "roles", default: [], null: false, array: true
    t.integer "sign_in_count", default: 0, null: false
    t.string "stripe_customer_id"
    t.datetime "subscription_ends_at"
    t.datetime "subscription_started_at"
    t.string "subscription_status", default: "trial"
    t.datetime "terms_accepted_at"
    t.string "timezone", default: "Australia/Sydney"
    t.datetime "trial_ends_at"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["kyc_status"], name: "index_users_on_kyc_status"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["roles"], name: "index_users_on_roles", using: :gin
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true, where: "(stripe_customer_id IS NOT NULL)"
    t.index ["subscription_status"], name: "index_users_on_subscription_status"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_conversations", "users"
  add_foreign_key "ai_messages", "ai_conversations"
  add_foreign_key "ai_voice_settings", "users", column: "updated_by_id"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "audit_logs", "users", column: "impersonated_by_id"
  add_foreign_key "buyer_profiles", "entities", column: "default_entity_id"
  add_foreign_key "buyer_profiles", "users"
  add_foreign_key "co_user_invitations", "users", column: "invitee_id"
  add_foreign_key "co_user_invitations", "users", column: "inviter_id"
  add_foreign_key "co_user_relationships", "co_user_invitations"
  add_foreign_key "co_user_relationships", "users", column: "co_user_id"
  add_foreign_key "co_user_relationships", "users", column: "primary_user_id"
  add_foreign_key "conversation_participants", "conversations"
  add_foreign_key "conversation_participants", "users"
  add_foreign_key "conversations", "properties"
  add_foreign_key "entities", "users"
  add_foreign_key "legal_document_acceptances", "legal_documents"
  add_foreign_key "legal_document_acceptances", "users"
  add_foreign_key "legal_documents", "users", column: "created_by_id"
  add_foreign_key "legal_documents", "users", column: "published_by_id"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "offers", "entities", column: "buyer_entity_id"
  add_foreign_key "offers", "offers", column: "counter_offer_id"
  add_foreign_key "offers", "properties"
  add_foreign_key "offers", "users", column: "buyer_id"
  add_foreign_key "properties", "entities"
  add_foreign_key "properties", "users"
  add_foreign_key "property_documents", "properties"
  add_foreign_key "property_documents", "users", column: "uploaded_by_id"
  add_foreign_key "property_enquiries", "entities"
  add_foreign_key "property_enquiries", "properties"
  add_foreign_key "property_enquiries", "users"
  add_foreign_key "property_loves", "properties"
  add_foreign_key "property_loves", "users"
  add_foreign_key "property_views", "properties"
  add_foreign_key "property_views", "users"
  add_foreign_key "provider_jobs", "properties"
  add_foreign_key "provider_jobs", "provider_leads"
  add_foreign_key "provider_jobs", "service_provider_profiles"
  add_foreign_key "provider_jobs", "transactions"
  add_foreign_key "provider_jobs", "users", column: "client_id"
  add_foreign_key "provider_leads", "properties"
  add_foreign_key "provider_leads", "service_provider_profiles"
  add_foreign_key "provider_leads", "users"
  add_foreign_key "review_disputes", "reviews"
  add_foreign_key "review_disputes", "users", column: "disputed_by_id"
  add_foreign_key "review_disputes", "users", column: "resolved_by_id"
  add_foreign_key "reviews", "users", column: "reviewee_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
  add_foreign_key "saved_searches", "users"
  add_foreign_key "seller_profiles", "entities", column: "default_entity_id"
  add_foreign_key "seller_profiles", "users"
  add_foreign_key "service_provider_profiles", "users"
  add_foreign_key "transaction_events", "transactions"
  add_foreign_key "transaction_events", "users"
  add_foreign_key "transactions", "entities", column: "buyer_entity_id"
  add_foreign_key "transactions", "entities", column: "seller_entity_id"
  add_foreign_key "transactions", "offers"
  add_foreign_key "transactions", "properties"
  add_foreign_key "transactions", "users", column: "buyer_conveyancer_id"
  add_foreign_key "transactions", "users", column: "buyer_id"
  add_foreign_key "transactions", "users", column: "seller_conveyancer_id"
  add_foreign_key "transactions", "users", column: "seller_id"
end
