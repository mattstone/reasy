# frozen_string_literal: true

module AI
  # Builds rich context about a user for AI interactions
  # Used to provide personalized, contextual AI responses
  class UserContextBuilder
    JOURNEY_STAGES = {
      exploring: "Just starting out, learning about the market",
      actively_searching: "Actively looking at properties and suburbs",
      making_offers: "Ready to make offers, has clear criteria",
      in_negotiation: "Has active offers or negotiations in progress",
      under_contract: "Has an accepted offer, working toward settlement",
      settled: "Has completed a transaction"
    }.freeze

    attr_reader :user

    def initialize(user)
      @user = user
    end

    # Build full context hash for AI system prompts
    def build
      {
        role: primary_role,
        journey_stage: journey_stage,
        journey_progress: journey_progress,
        profile: profile_context,
        activity: activity_context,
        preferences: preference_context
      }
    end

    # Build a natural language summary for AI context
    def to_prompt
      parts = []

      parts << role_summary
      parts << journey_summary
      parts << profile_summary if profile_present?
      parts << activity_summary if has_activity?
      parts << preference_summary if has_preferences?

      parts.compact.join("\n\n")
    end

    private

    # Determine user's primary role
    def primary_role
      if @user.seller? && @user.properties.listed.any?
        :seller
      elsif @user.buyer?
        :buyer
      elsif @user.service_provider?
        :service_provider
      else
        :unknown
      end
    end

    # Determine where user is in their property journey
    def journey_stage
      return :settled if has_completed_transaction?
      return :under_contract if has_accepted_offer?
      return :in_negotiation if has_pending_offers?
      return :making_offers if ready_to_offer?
      return :actively_searching if actively_searching?

      :exploring
    end

    def journey_progress
      journey_type = primary_role == :seller ? "seller" : "buyer"
      {
        level: @user.journey_level,
        title: @user.journey_title,
        points: @user.journey_points,
        completion_percentage: @user.journey_completion_percentage(journey_type),
        next_checklist_items: pending_checklist_items(journey_type, limit: 3)
      }
    end

    def profile_context
      case primary_role
      when :buyer
        buyer_profile_context
      when :seller
        seller_profile_context
      when :service_provider
        service_provider_context
      else
        {}
      end
    end

    def buyer_profile_context
      profile = @user.buyer_profile
      return {} unless profile

      {
        budget_min: profile.budget_min,
        budget_max: profile.budget_max,
        finance_status: profile.finance_status,
        pre_approval_valid: profile.pre_approval_valid?,
        first_home_buyer: profile.first_home_buyer,
        buying_timeline: profile.buying_timeline,
        property_types: profile.property_types,
        bedrooms_min: profile.bedrooms_min,
        must_have_features: profile.must_have_features,
        search_areas: profile.search_areas,
        score_weights: profile.effective_score_weights
      }
    end

    def seller_profile_context
      profile = @user.seller_profile
      return {} unless profile

      {
        settlement_preference: profile.preferred_settlement_period,
        settlement_days: profile.settlement_days,
        accepted_finance_types: profile.accepted_finance_types,
        allow_direct_contact: profile.allow_direct_contact,
        allow_scheduled_viewings: profile.allow_scheduled_viewings
      }
    end

    def service_provider_context
      profile = @user.service_provider_profile
      return {} unless profile

      {
        business_name: profile.business_name,
        service_type: profile.service_type,
        service_areas: profile.service_areas
      }
    end

    def activity_context
      {
        saved_properties_count: @user.loved_properties.count,
        recent_saved_properties: recent_saved_properties,
        saved_searches_count: @user.saved_searches.active.count,
        offers_made_count: @user.offers_made.count,
        active_offers_count: @user.offers_made.where(status: %w[pending submitted viewed countered]).count,
        properties_listed_count: @user.properties.listed.count,
        recent_conversations: recent_conversations,
        last_activity_at: @user.current_sign_in_at
      }
    end

    def preference_context
      {
        preferred_agent: @user.preferred_agent,
        notification_preferences: nil, # Future: pull from user settings
        communication_style: infer_communication_style
      }
    end

    # Natural language summaries for prompts

    def role_summary
      case primary_role
      when :buyer
        "This user is a property BUYER."
      when :seller
        "This user is a property SELLER with #{@user.properties.listed.count} active listing(s)."
      when :service_provider
        profile = @user.service_provider_profile
        "This user is a SERVICE PROVIDER (#{profile&.service_type || 'unknown type'})."
      else
        "This user hasn't completed their profile yet."
      end
    end

    def journey_summary
      stage = journey_stage
      progress = journey_progress

      lines = []
      lines << "Journey stage: #{stage.to_s.humanize} - #{JOURNEY_STAGES[stage]}"
      lines << "Level #{progress[:level]}: #{progress[:title]} (#{progress[:points]} points)"

      if progress[:completion_percentage] < 100 && progress[:next_checklist_items].any?
        items = progress[:next_checklist_items].map(&:title).join(", ")
        lines << "Next steps: #{items}"
      end

      lines.join("\n")
    end

    def profile_summary
      context = profile_context
      return nil if context.empty?

      case primary_role
      when :buyer
        buyer_profile_summary(context)
      when :seller
        seller_profile_summary(context)
      else
        nil
      end
    end

    def buyer_profile_summary(context)
      lines = []

      if context[:budget_min] && context[:budget_max]
        lines << "Budget: $#{format_number(context[:budget_min])} - $#{format_number(context[:budget_max])}"
      end

      lines << "Finance: #{context[:finance_status]&.humanize}" if context[:finance_status]
      lines << "First home buyer: Yes" if context[:first_home_buyer]
      lines << "Timeline: #{context[:buying_timeline]&.humanize}" if context[:buying_timeline]

      if context[:property_types]&.any?
        lines << "Property types: #{context[:property_types].map(&:humanize).join(', ')}"
      end

      if context[:bedrooms_min]
        lines << "Bedrooms: #{context[:bedrooms_min]}+"
      end

      if context[:must_have_features]&.any?
        lines << "Must-haves: #{context[:must_have_features].map(&:humanize).join(', ')}"
      end

      if context[:search_areas]&.any?
        lines << "Preferred areas: #{context[:search_areas].first(5).join(', ')}"
      end

      "Buyer Profile:\n#{lines.join("\n")}"
    end

    def seller_profile_summary(context)
      lines = []

      lines << "Settlement preference: #{context[:settlement_preference]&.humanize}"
      lines << "Accepts: #{context[:accepted_finance_types]&.map(&:humanize)&.join(', ')}"

      "Seller Profile:\n#{lines.join("\n")}"
    end

    def activity_summary
      context = activity_context
      lines = []

      lines << "Saved properties: #{context[:saved_properties_count]}" if context[:saved_properties_count] > 0
      lines << "Active saved searches: #{context[:saved_searches_count]}" if context[:saved_searches_count] > 0
      lines << "Offers made: #{context[:offers_made_count]} (#{context[:active_offers_count]} active)" if context[:offers_made_count] > 0
      lines << "Properties listed: #{context[:properties_listed_count]}" if context[:properties_listed_count] > 0

      return nil if lines.empty?

      "Recent Activity:\n#{lines.join("\n")}"
    end

    def preference_summary
      return nil unless @user.has_preferred_agent?

      "Preferred AI assistant: #{@user.preferred_agent_name}"
    end

    # Helper methods

    def profile_present?
      case primary_role
      when :buyer then @user.buyer_profile.present?
      when :seller then @user.seller_profile.present?
      when :service_provider then @user.service_provider_profile.present?
      else false
      end
    end

    def has_activity?
      @user.loved_properties.any? ||
        @user.saved_searches.any? ||
        @user.offers_made.any? ||
        @user.properties.any?
    end

    def has_preferences?
      @user.has_preferred_agent?
    end

    def has_completed_transaction?
      @user.transactions_as_buyer.where(status: "settled").any? ||
        @user.transactions_as_seller.where(status: "settled").any?
    end

    def has_accepted_offer?
      @user.offers_made.where(status: "accepted").any? ||
        @user.properties.joins(:offers).where(offers: { status: "accepted" }).any?
    end

    def has_pending_offers?
      @user.offers_made.where(status: %w[pending submitted viewed countered]).any? ||
        @user.properties.joins(:offers).where(offers: { status: %w[pending submitted viewed countered] }).any?
    end

    def ready_to_offer?
      return false unless @user.buyer?

      profile = @user.buyer_profile
      return false unless profile

      profile.budget_max.present? &&
        (profile.pre_approved? || profile.cash_buyer?)
    end

    def actively_searching?
      @user.saved_searches.active.any? ||
        @user.loved_properties.where("created_at > ?", 30.days.ago).any?
    end

    def pending_checklist_items(journey_type, limit: 3)
      checklist = JourneyChecklist.find_by(journey_type: journey_type)
      return [] unless checklist

      completed_ids = @user.user_checklist_progresses.completed.pluck(:checklist_item_id)

      checklist.checklist_items
        .where.not(id: completed_ids)
        .order(:position)
        .limit(limit)
    end

    def recent_saved_properties
      @user.loved_properties
        .includes(:suburb_profile)
        .order("property_loves.created_at DESC")
        .limit(5)
        .map { |p| { id: p.id, address: p.full_address, suburb: p.suburb } }
    end

    def recent_conversations
      @user.ai_conversations
        .order(updated_at: :desc)
        .limit(3)
        .map { |c| { id: c.id, assistant: c.assistant, last_message_at: c.updated_at } }
    end

    def infer_communication_style
      # Future: analyze past conversation patterns
      # For now, return default
      :balanced
    end

    def format_number(num)
      return nil unless num

      num.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
  end
end
