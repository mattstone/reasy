# frozen_string_literal: true

# Background job to generate personalized AI analysis for a property
# Uses PropertyContextBuilder to gather context and Claude to generate insights
class GeneratePropertyAnalysisJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff for API failures
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  # Don't retry on record not found
  discard_on ActiveRecord::RecordNotFound

  def perform(property_id, user_id)
    property = Property.find(property_id)
    user = User.find(user_id)

    # Find or create the analysis record
    analysis = PropertyAnalysis.find_or_create_pending(property: property, user: user)

    # Skip if already completed and valid
    return if analysis.valid?

    # Mark as processing
    analysis.start_processing!

    begin
      # Build context
      context_builder = AI::PropertyContextBuilder.new(property, user)
      context = context_builder.build

      # Generate AI analysis using Claude
      result = generate_ai_analysis(property, user, context, context_builder)

      # Store results
      analysis.complete!(
        match_score: result[:match_score],
        strengths: result[:strengths],
        considerations: result[:considerations],
        suggestion: result[:suggestion],
        ai_badges: result[:badges],
        context_snapshot: {
          property_price_cents: property.price_cents,
          user_budget_max_cents: user.buyer_profile&.budget_max_cents,
          reasy_score: property.reasy_score,
          generated_at: Time.current.iso8601
        },
        model_version: result[:model_version]
      )
    rescue StandardError => e
      analysis.fail!(e.message)
      raise # Re-raise to trigger retry
    end
  end

  private

  def generate_ai_analysis(property, user, context, context_builder)
    client = AI::ClaudeClient.new

    # Build the analysis prompt
    prompt = build_analysis_prompt(property, user, context, context_builder)

    # Get the appropriate agent based on user preference
    agent = user.preferred_agent || "stevie"

    # Make the API call
    response = client.chat(
      messages: [{ role: "user", content: prompt }],
      system_prompt: build_system_prompt(agent, user)
    )

    # Parse the structured response
    parse_analysis_response(response, context_builder)
  end

  def build_system_prompt(agent, user)
    agent_name = agent == "evie" ? "Evie" : "Stevie"
    agent_style = if agent == "evie"
                    "warm, supportive, and thorough. You celebrate wins and gently point out concerns."
                  else
                    "practical, straight-talking, and efficient. You get to the point while being friendly."
                  end

    <<~PROMPT
      You are #{agent_name}, the property sensei for Reasy, an Australian property platform.
      Your style is #{agent_style}

      You're providing a personalized property analysis for #{user.name.split.first}.
      Your job is to help them understand if this property is right for THEM specifically,
      based on their preferences, budget, and needs.

      Be honest and helpful. Point out both the positives and the concerns.
      Keep your language conversational and use Australian English.

      IMPORTANT: Structure your response as JSON with these fields:
      {
        "match_score": 0-100 (how well this property matches their needs),
        "strengths": ["strength 1", "strength 2", ...] (what's good about this property for them),
        "considerations": ["consideration 1", ...] (things they should think about or concerns),
        "suggestion": "A short paragraph of actionable advice for this specific property"
      }

      Respond ONLY with valid JSON, no additional text.
    PROMPT
  end

  def build_analysis_prompt(property, user, context, context_builder)
    # Get natural language context
    context_text = context_builder.to_prompt

    <<~PROMPT
      Analyze this property for a potential buyer.

      #{context_text}

      Based on all of this information, provide your personalized assessment.
      Consider:
      - How well does this property match their stated preferences?
      - Is it within their budget? If not, by how much?
      - Are their must-have features present?
      - Are there any deal-breakers for this person?
      - What are the location pros and cons for their needs?
      - Are there any risks they should be aware of?
      - Is this a good investment based on the data?

      Provide your analysis as structured JSON.
    PROMPT
  end

  def parse_analysis_response(response, context_builder)
    # Handle mocked responses
    if response[:mocked]
      return generate_fallback_analysis(context_builder)
    end

    content = response[:response]

    # Try to parse as JSON
    begin
      # Extract JSON from response (handle potential markdown code blocks)
      json_match = content.match(/\{[\s\S]*\}/)
      parsed = JSON.parse(json_match[0]) if json_match

      if parsed
        {
          match_score: parsed["match_score"]&.to_i || context_builder.send(:match_score) || 50,
          strengths: Array(parsed["strengths"]),
          considerations: Array(parsed["considerations"]),
          suggestion: parsed["suggestion"].to_s,
          badges: context_builder.badges,
          model_version: response[:model]
        }
      else
        generate_fallback_analysis(context_builder)
      end
    rescue JSON::ParserError
      # Fallback to context-based analysis
      generate_fallback_analysis(context_builder)
    end
  end

  # Generate analysis from context when AI fails or is mocked
  def generate_fallback_analysis(context_builder)
    {
      match_score: context_builder.send(:match_score) || 50,
      strengths: context_builder.send(:strengths_for_user) || [],
      considerations: context_builder.send(:considerations_for_user) || [],
      suggestion: generate_fallback_suggestion(context_builder),
      badges: context_builder.badges,
      model_version: "fallback"
    }
  end

  def generate_fallback_suggestion(context_builder)
    score = context_builder.send(:match_score) || 50

    case score
    when 80..100
      "This property looks like a strong match for your criteria. Consider scheduling an inspection to see it in person."
    when 65..79
      "This property has several features that align with your needs. It's worth a closer look, but check the considerations carefully."
    when 50..64
      "This property has some positives but also some gaps with your preferences. Make sure the trade-offs work for you."
    when 30..49
      "This property may not be the best fit based on your criteria. Consider whether the positives outweigh the concerns."
    else
      "Based on your preferences, this property has significant gaps. You may want to prioritize other options."
    end
  end
end
