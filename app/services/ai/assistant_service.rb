# frozen_string_literal: true

module AI
  # Main service for interacting with AI assistants
  #
  # PRIMARY ASSISTANTS (Recommended):
  # - Stevie: Your Property Sensei (male) - practical, straight-talking guide
  # - Evie: Your Property Sensei (female) - supportive, thorough companion
  #
  # LEGACY ASSISTANTS (Deprecated - for existing conversations):
  # - Max: Property Expert - helps understand property features and value
  # - Sage: Journey Guide - guides through the buying/selling process
  # - Nina: Negotiation Advisor - helps with offers and negotiations
  # - Doc: Document Decoder - explains legal documents in plain English
  # - Scout: Market Researcher - provides market data and insights
  # - Ally: Service Provider Assistant - helps find trusted professionals
  #
  class AssistantService
    # Full expertise list for the primary sensei agents
    SENSEI_EXPERTISE = %w[
      property_features valuations inspections renovations zoning
      process_guidance timelines checklists milestones
      offers negotiation pricing strategy
      contracts legal_documents terms_conditions due_diligence
      market_data comparable_sales suburb_insights trends
      conveyancers inspectors mortgage_brokers service_providers
      buyer_guidance seller_guidance
    ].freeze

    ASSISTANTS = {
      # PRIMARY ASSISTANTS - Users choose one as their personal sensei
      stevie: {
        name: "Stevie",
        title: "Your Property Sensei",
        description: "Your property transaction wingman. Practical, straight-talking, gets things done without the fluff.",
        expertise: SENSEI_EXPERTISE,
        primary: true,
        gender: :male,
        avatar: "businessman"
      },
      evie: {
        name: "Evie",
        title: "Your Property Sensei",
        description: "Your property journey companion. Patient, thorough, celebrates every milestone with you.",
        expertise: SENSEI_EXPERTISE,
        primary: true,
        gender: :female,
        avatar: "businesswoman"
      },
      # LEGACY ASSISTANTS - Deprecated but maintained for existing conversations
      max: {
        name: "Max",
        title: "Property Expert",
        description: "Your friendly property guru who knows buildings inside and out",
        expertise: %w[property_features valuations inspections renovations zoning],
        deprecated: true
      },
      sage: {
        name: "Sage",
        title: "Journey Guide",
        description: "Your wise companion through the property journey",
        expertise: %w[process_guidance timelines checklists milestones],
        deprecated: true
      },
      nina: {
        name: "Nina",
        title: "Negotiation Advisor",
        description: "Your strategic partner in getting the best deal",
        expertise: %w[offers negotiation pricing strategy],
        deprecated: true
      },
      doc: {
        name: "Doc",
        title: "Document Decoder",
        description: "Makes legal jargon understandable",
        expertise: %w[contracts legal_documents terms_conditions due_diligence],
        deprecated: true
      },
      scout: {
        name: "Scout",
        title: "Market Researcher",
        description: "Your data-driven market analyst",
        expertise: %w[market_data comparable_sales suburb_insights trends],
        deprecated: true
      },
      ally: {
        name: "Ally",
        title: "Service Provider Assistant",
        description: "Connects you with trusted professionals",
        expertise: %w[conveyancers inspectors mortgage_brokers service_providers],
        deprecated: true
      }
    }.freeze

    # Primary assistants that new users should choose from
    PRIMARY_ASSISTANTS = ASSISTANTS.select { |_, v| v[:primary] }.keys.freeze

    # Deprecated assistants (for legacy support)
    LEGACY_ASSISTANTS = ASSISTANTS.select { |_, v| v[:deprecated] }.keys.freeze

    attr_reader :user, :assistant_type, :conversation

    def initialize(user:, assistant_type:, conversation: nil)
      @user = user
      @assistant_type = assistant_type.to_sym
      @conversation = conversation
      @client = ClaudeClient.new

      validate_assistant_type!
    end

    def assistant_info
      ASSISTANTS[@assistant_type]
    end

    def mocked?
      ClaudeClient.mocked?
    end

    def mocked_status_message
      ClaudeClient.status_message
    end

    # Start a new conversation with an assistant
    def start_conversation(context: {})
      @conversation = user.ai_conversations.create!(
        assistant: @assistant_type.to_s,
        metadata: { context: context }
      )

      # Add system message
      system_prompt = build_system_prompt(context)
      @conversation.ai_messages.create!(
        role: "system",
        content: system_prompt,
        tokens_used: estimate_tokens(system_prompt)
      )

      @conversation
    end

    # Send a message and get a response
    def chat(message, context: {})
      ensure_conversation!(context)

      # Record user message
      user_message = @conversation.add_message(
        role: "user",
        content: message
      )

      # Get AI response
      response = @client.chat(
        messages: build_messages_array,
        system_prompt: build_system_prompt(context)
      )

      # Record assistant response
      assistant_message = @conversation.add_message(
        role: "assistant",
        content: response[:response],
        tokens_used: response.dig(:usage, :output_tokens) || 0,
        model_version: response[:model],
        prompt_context: {
          mocked: response[:mocked],
          input_tokens: response.dig(:usage, :input_tokens)
        }
      )

      # Update conversation token counts (add_message already increments total_tokens)
      # No additional update needed as add_message handles this

      {
        message: assistant_message,
        mocked: response[:mocked],
        mocked_warning: response[:mocked_warning]
      }
    end

    # Stream a response (for real-time UI updates)
    def stream_chat(message, context: {}, &block)
      ensure_conversation!(context)

      # Record user message
      @conversation.add_message(role: "user", content: message)

      full_response = ""

      @client.stream_chat(
        messages: build_messages_array,
        system_prompt: build_system_prompt(context)
      ) do |chunk|
        if chunk[:type] == "content_block_delta"
          text = chunk.dig(:delta, :text) || ""
          full_response += text
          yield({ type: "delta", text: text })
        elsif chunk[:type] == "message_stop"
          yield({ type: "done", mocked: chunk[:mocked] })
        end
      end

      # Record full response
      @conversation.add_message(
        role: "assistant",
        content: full_response,
        prompt_context: { streamed: true }
      )
    end

    # Get suggested questions based on context
    def suggested_questions(context: {})
      case @assistant_type
      when :stevie, :evie
        sensei_suggestions(context)
      when :max
        property_expert_suggestions(context)
      when :sage
        journey_guide_suggestions(context)
      when :nina
        negotiation_suggestions(context)
      when :doc
        document_suggestions(context)
      when :scout
        research_suggestions(context)
      when :ally
        service_provider_suggestions(context)
      end
    end

    # Check if this is a primary (sensei) assistant
    def primary_assistant?
      assistant_info[:primary] == true
    end

    # Check if this is a deprecated assistant
    def deprecated_assistant?
      assistant_info[:deprecated] == true
    end

    # Get the assistant type for the user's preferred agent
    def self.for_user(user)
      return nil unless user.has_preferred_agent?
      user.preferred_agent.to_sym
    end

    private

    def validate_assistant_type!
      unless ASSISTANTS.key?(@assistant_type)
        raise ArgumentError, "Invalid assistant type: #{@assistant_type}. Valid types: #{ASSISTANTS.keys.join(', ')}"
      end
    end

    def ensure_conversation!(context)
      @conversation ||= start_conversation(context: context)
    end

    def build_system_prompt(context)
      voice_setting = AIVoiceSetting.for(@assistant_type.to_s)
      base_prompt = voice_setting&.build_system_prompt || default_system_prompt

      # Add context-specific instructions
      context_prompt = build_context_prompt(context)

      # Add mocked warning if applicable
      mocked_notice = if mocked?
        "\n\n[SYSTEM NOTE: API is currently MOCKED. Responses are simulated for development/testing.]"
      else
        ""
      end

      "#{base_prompt}\n\n#{context_prompt}#{mocked_notice}"
    end

    def default_system_prompt
      info = assistant_info

      <<~PROMPT
        You are #{info[:name]}, the #{info[:title]} for Reasy, an Australian property platform.

        #{info[:description]}

        Your expertise areas: #{info[:expertise].join(', ')}

        Guidelines:
        - Be friendly, helpful, and use Australian English
        - Keep responses concise but informative
        - Always consider Australian property laws and practices
        - Be encouraging but honest - never oversell or mislead
        - If you don't know something, say so and suggest who might help
        - Reference other Reasy assistants when appropriate
      PROMPT
    end

    def build_context_prompt(context)
      parts = []

      if context[:property].present?
        property = context[:property]
        parts << "Current property: #{property.full_address} (#{property.property_type}, #{property.bedrooms} bed, #{property.bathrooms} bath)"
        parts << "Listed at: #{property.price_range_display}" if property.price_cents.present?
      end

      if context[:offer].present?
        offer = context[:offer]
        parts << "Current offer: $#{offer.amount&.to_i&.to_s(:delimited)} (#{offer.status})"
      end

      if context[:transaction].present?
        transaction = context[:transaction]
        parts << "Transaction status: #{transaction.status}"
        parts << "Settlement date: #{transaction.settlement_date}" if transaction.settlement_date.present?
      end

      parts.join("\n")
    end

    def build_messages_array
      @conversation.ai_messages.where(role: %w[user assistant]).order(:created_at).map do |msg|
        { role: msg.role, content: msg.content }
      end
    end

    def estimate_tokens(text)
      (text.length / 4.0).ceil
    end

    # Suggested questions for each assistant
    def property_expert_suggestions(context)
      [
        "What should I look for during a property inspection?",
        "How do I assess if a property is good value?",
        "What renovation potential does this property have?",
        "Can you explain the zoning for this area?"
      ]
    end

    def journey_guide_suggestions(context)
      [
        "What are the steps to buying a property in Australia?",
        "How long does the typical buying process take?",
        "What should I have ready before making an offer?",
        "What happens after my offer is accepted?"
      ]
    end

    def negotiation_suggestions(context)
      [
        "How should I structure my first offer?",
        "What's a reasonable discount to negotiate?",
        "How do I respond to a counter-offer?",
        "What conditions should I include in my offer?"
      ]
    end

    def document_suggestions(context)
      [
        "What should I look for in a contract of sale?",
        "Can you explain what a Section 32 statement is?",
        "What are the key terms I should understand?",
        "What does the cooling-off period mean?"
      ]
    end

    def research_suggestions(context)
      [
        "What are comparable sales in this area?",
        "Is this suburb a good investment?",
        "What's the rental yield like here?",
        "How has the market changed recently?"
      ]
    end

    def service_provider_suggestions(context)
      [
        "How do I choose a good conveyancer?",
        "What should a building inspection cover?",
        "When do I need a mortgage broker?",
        "How do I find a trusted pest inspector?"
      ]
    end

    # Comprehensive suggestions for Stevie/Evie based on user role and context
    def sensei_suggestions(context)
      suggestions = []

      # Role-based suggestions
      if @user.buyer?
        suggestions += buyer_sensei_suggestions(context)
      elsif @user.seller?
        suggestions += seller_sensei_suggestions(context)
      end

      # Context-based additions
      if context[:property].present?
        suggestions << "What should I know about this property?"
        suggestions << "Can you analyze the Reasy Score for this area?"
      end

      if context[:contract_analysis].present?
        suggestions << "Explain the unusual clauses you found"
        suggestions << "What questions should I ask my conveyancer?"
      end

      if context[:transaction].present?
        suggestions << "What's my next step in the transaction?"
        suggestions << "When should I be concerned about deadlines?"
      end

      # Fallback general suggestions
      if suggestions.empty?
        suggestions = [
          "What's the first step in buying a property?",
          "How do I find properties in my budget?",
          "What documents do I need to prepare?",
          "Can you explain the buying/selling process?"
        ]
      end

      suggestions.first(6)
    end

    def buyer_sensei_suggestions(context)
      # Check user's checklist progress to provide relevant suggestions
      [
        "What should I complete on my buyer checklist?",
        "How do I analyze a contract for unusual clauses?",
        "What questions should I ask during an inspection?",
        "How do I structure a competitive offer?",
        "What happens during the cooling-off period?",
        "How do I choose the right conveyancer?"
      ]
    end

    def seller_sensei_suggestions(context)
      [
        "What should I complete on my seller checklist?",
        "How do I price my property correctly?",
        "What documents do I need to prepare for sale?",
        "How should I respond to buyer offers?",
        "What makes a good contract of sale?",
        "How do I prepare for settlement?"
      ]
    end
  end
end
