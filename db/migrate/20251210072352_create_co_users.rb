# frozen_string_literal: true

class CreateCoUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :co_user_invitations do |t|
      # The main user who is inviting
      t.references :inviter, null: false, foreign_key: { to_table: :users }, index: true

      # The invited user (nullable until accepted)
      t.references :invitee, foreign_key: { to_table: :users }, index: true

      # Invitation details
      t.string :email, null: false
      t.string :name
      t.string :relationship # partner, parent, friend, advisor, etc.

      # Invitation token for acceptance
      t.string :invitation_token, null: false
      t.datetime :invitation_sent_at
      t.datetime :invitation_accepted_at
      t.datetime :invitation_expires_at

      # Status: pending, accepted, declined, expired, revoked
      t.string :status, default: "pending", null: false

      t.timestamps
    end

    add_index :co_user_invitations, :invitation_token, unique: true
    add_index :co_user_invitations, :email
    add_index :co_user_invitations, :status

    # Co-user relationships (active co-user access)
    create_table :co_user_relationships do |t|
      # The main account holder
      t.references :primary_user, null: false, foreign_key: { to_table: :users }, index: true

      # The co-user with access
      t.references :co_user, null: false, foreign_key: { to_table: :users }, index: true

      # From which invitation
      t.references :co_user_invitation, foreign_key: true

      # Relationship type
      t.string :relationship

      # Permissions (can be customized)
      t.boolean :can_view_listings, default: true
      t.boolean :can_view_offers, default: true
      t.boolean :can_send_messages, default: true
      t.boolean :can_schedule_viewings, default: false
      t.boolean :can_make_offers, default: false

      # Status: active, suspended, revoked
      t.string :status, default: "active", null: false

      # Subscription info (co-users pay 80% less)
      t.string :subscription_status, default: "trial"
      t.datetime :subscription_started_at
      t.datetime :subscription_ends_at
      t.string :stripe_subscription_id

      t.timestamps
    end

    add_index :co_user_relationships, [:primary_user_id, :co_user_id], unique: true, name: "idx_co_user_unique_pair"
    add_index :co_user_relationships, :status
  end
end
