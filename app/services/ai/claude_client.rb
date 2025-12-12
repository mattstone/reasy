# frozen_string_literal: true

module AI
  # Claude API Client
  #
  # ╔═══════════════════════════════════════════════════════════════════════════════╗
  # ║                                                                               ║
  # ║   🚨 MOCKED API - Claude API requests are currently MOCKED 🚨                 ║
  # ║                                                                               ║
  # ║   To enable real API calls:                                                   ║
  # ║   1. Set ANTHROPIC_API_KEY environment variable                               ║
  # ║   2. Set CLAUDE_API_MOCKED=false in your environment                          ║
  # ║                                                                               ║
  # ║   Current status: #{ENV.fetch('CLAUDE_API_MOCKED', 'true') == 'true' ? 'MOCKED' : 'LIVE'}                                                     ║
  # ║                                                                               ║
  # ╚═══════════════════════════════════════════════════════════════════════════════╝
  #
  class ClaudeClient
    MOCK_RESPONSE_DELAY = 0.5 # seconds - simulates API latency

    class << self
      def mocked?
        ENV.fetch("CLAUDE_API_MOCKED", "true") == "true" || ENV["ANTHROPIC_API_KEY"].blank?
      end

      def status_message
        if mocked?
          "[MOCKED] Claude API requests are being simulated. Set ANTHROPIC_API_KEY and CLAUDE_API_MOCKED=false for real responses."
        else
          "[LIVE] Connected to Claude API"
        end
      end
    end

    def initialize
      @api_key = ENV["ANTHROPIC_API_KEY"]
      @model = ENV.fetch("CLAUDE_MODEL", "claude-3-5-sonnet-20241022")
      @base_url = "https://api.anthropic.com/v1"

      log_status
    end

    def chat(messages:, system_prompt: nil, max_tokens: 1024, temperature: 0.7)
      if self.class.mocked?
        mock_chat_response(messages: messages, system_prompt: system_prompt)
      else
        real_chat_response(messages: messages, system_prompt: system_prompt, max_tokens: max_tokens, temperature: temperature)
      end
    end

    def stream_chat(messages:, system_prompt: nil, max_tokens: 1024, temperature: 0.7, &block)
      if self.class.mocked?
        mock_stream_response(messages: messages, &block)
      else
        real_stream_response(messages: messages, system_prompt: system_prompt, max_tokens: max_tokens, temperature: temperature, &block)
      end
    end

    private

    def log_status
      Rails.logger.info("=" * 80)
      Rails.logger.info("Claude API Client Initialized")
      Rails.logger.info(self.class.status_message)
      Rails.logger.info("=" * 80)
    end

    # ╔═════════════════════════════════════════╗
    # ║         MOCKED RESPONSES                 ║
    # ╚═════════════════════════════════════════╝

    def mock_chat_response(messages:, system_prompt: nil)
      sleep(MOCK_RESPONSE_DELAY) if Rails.env.development?

      last_message = messages.last&.dig(:content) || ""

      {
        success: true,
        mocked: true,
        mocked_warning: "⚠️ This response is MOCKED. Set up ANTHROPIC_API_KEY for real AI responses.",
        response: generate_mock_response(last_message, system_prompt),
        usage: {
          input_tokens: estimate_tokens(messages.to_json + system_prompt.to_s),
          output_tokens: 150
        },
        model: "#{@model} (MOCKED)"
      }
    end

    def mock_stream_response(messages:)
      last_message = messages.last&.dig(:content) || ""
      response = generate_mock_response(last_message, nil)

      # Simulate streaming by yielding chunks
      response.chars.each_slice(20) do |chunk|
        sleep(0.05) if Rails.env.development?
        yield({ type: "content_block_delta", delta: { text: chunk.join } })
      end

      yield({ type: "message_stop", mocked: true })
    end

    def generate_mock_response(user_message, system_prompt)
      # Determine which assistant is being used from system prompt
      assistant = detect_assistant(system_prompt)

      case assistant
      when :max
        mock_max_response(user_message)
      when :sage
        mock_sage_response(user_message)
      when :nina
        mock_nina_response(user_message)
      when :doc
        mock_doc_response(user_message)
      when :scout
        mock_scout_response(user_message)
      when :ally
        mock_ally_response(user_message)
      else
        mock_generic_response(user_message)
      end
    end

    def detect_assistant(system_prompt)
      return :generic if system_prompt.blank?

      case system_prompt.downcase
      when /max|property expert/i then :max
      when /sage|journey guide/i then :sage
      when /nina|negotiation/i then :nina
      when /doc|document/i then :doc
      when /scout|market research/i then :scout
      when /ally|service provider/i then :ally
      else :generic
      end
    end

    def mock_max_response(message)
      responses = [
        "[MOCKED RESPONSE - Max the Property Expert]\n\nG'day! Based on what you've described, that property sounds like it has some solid fundamentals. The location in that suburb typically sees strong demand from families looking for good school catchments.\n\nA few things to consider:\n- Check the orientation for natural light\n- Look at the zoning for any future development nearby\n- Get a building inspection to assess structural integrity\n\nWant me to dig deeper into any specific aspect of this property?",
        "[MOCKED RESPONSE - Max the Property Expert]\n\nThat's a great question about property features! In my experience, buyers in this market really value:\n\n1. **Indoor-outdoor flow** - Aussies love their alfresco areas\n2. **Storage** - Never underestimate good storage\n3. **Parking** - At least 2 spaces for most families\n4. **Energy efficiency** - Solar panels and good insulation\n\nShall I explain how any of these might affect the property value?"
      ]
      responses.sample
    end

    def mock_sage_response(message)
      responses = [
        "[MOCKED RESPONSE - Sage the Journey Guide]\n\nI can see you're navigating the exciting (and sometimes overwhelming!) property journey. Let me break down where you are and what comes next:\n\n**Current Stage:** Property Search\n**Next Steps:**\n1. Shortlist properties that meet your criteria\n2. Book inspections for your top picks\n3. Get pre-approval sorted if you haven't already\n\nRemember, there's no rush - finding the right property is a marathon, not a sprint. What would you like to focus on first?",
        "[MOCKED RESPONSE - Sage the Journey Guide]\n\nEvery property journey is unique, but here's a typical timeline to keep in mind:\n\n📅 **Week 1-4:** Research & pre-approval\n📅 **Week 4-12:** Active property search\n📅 **Week 12-16:** Make offers, negotiate\n📅 **Week 16-22:** Due diligence & exchange\n📅 **Week 22-28:** Settlement preparation\n\nOf course, this can vary. Would you like me to help you map out your personal timeline?"
      ]
      responses.sample
    end

    def mock_nina_response(message)
      responses = [
        "[MOCKED RESPONSE - Nina the Negotiation Advisor]\n\nLet's talk strategy! When it comes to making an offer, timing and presentation matter just as much as the number.\n\n**Key negotiation tips:**\n- Research recent sales in the area\n- Understand the seller's motivation\n- Don't lowball too aggressively - it can backfire\n- Be prepared to move quickly if they counter\n\nWhat's your current thinking on the offer amount? I can help you position it effectively.",
        "[MOCKED RESPONSE - Nina the Negotiation Advisor]\n\nA counter-offer? This is actually a good sign - it means the seller is engaged!\n\nHere's how I'd approach this:\n1. **Don't react emotionally** - Take time to consider\n2. **Look at the gap** - How far apart are you?\n3. **Consider non-price terms** - Settlement dates, inclusions\n4. **Have your walk-away number** - Know your limit\n\nWant me to help you craft your response?"
      ]
      responses.sample
    end

    def mock_doc_response(message)
      responses = [
        "[MOCKED RESPONSE - Doc the Document Decoder]\n\nAh, the contract of sale - I know legal documents can be daunting, but let me help demystify this one!\n\n**Key sections to focus on:**\n- **Special Conditions** - These are negotiable terms\n- **Cooling-off period** - Usually 5 business days in NSW\n- **Deposit requirements** - Typically 10% but can vary\n- **Inclusions/Exclusions** - What stays, what goes\n\nWould you like me to explain any section in plain English?",
        "[MOCKED RESPONSE - Doc the Document Decoder]\n\nI've reviewed the document structure. Here's what I found:\n\n📄 **Document Type:** Section 32 Vendor Statement\n📋 **Key Information:**\n- Title details and encumbrances\n- Planning certificates\n- Building permits\n- Services and utilities\n\n⚠️ **Flags to discuss with your conveyancer:**\n- Any easements or covenants\n- Outstanding rates or levies\n\nWant me to break down any specific section?"
      ]
      responses.sample
    end

    def mock_scout_response(message)
      responses = [
        "[MOCKED RESPONSE - Scout the Market Researcher]\n\nI've done some digging on that area. Here's what the data tells us:\n\n📊 **Market Snapshot:**\n- Median house price: $1.2M (up 5% YoY)\n- Days on market: 28 average\n- Auction clearance rate: 72%\n- Rental yield: 3.2%\n\n🏘️ **Recent Comparable Sales:**\n- 12 Smith St: $1.15M (3 bed, similar condition)\n- 45 Jones Ave: $1.28M (4 bed, renovated)\n\nShall I dive deeper into any of these metrics?",
        "[MOCKED RESPONSE - Scout the Market Researcher]\n\nGreat question about the suburb growth potential! Here's my analysis:\n\n📈 **Growth Indicators:**\n- New transport infrastructure planned\n- School rankings improving\n- Retail/hospitality development increasing\n- Young family demographic growing\n\n📉 **Risk Factors:**\n- Interest rate sensitivity\n- High-density development approvals\n\nOverall, I'd rate this suburb as having moderate-high growth potential over 5-10 years. Want more detail on any factor?"
      ]
      responses.sample
    end

    def mock_ally_response(message)
      responses = [
        "[MOCKED RESPONSE - Ally the Service Provider Assistant]\n\nLooking for a conveyancer? Great thinking - having the right team is crucial!\n\nHere's what to look for:\n✅ Licensed and insured\n✅ Experience in your area\n✅ Clear fee structure\n✅ Good communication style\n✅ Availability for your timeline\n\nI can help you find pre-vetted professionals in our network. What suburb is the property in?",
        "[MOCKED RESPONSE - Ally the Service Provider Assistant]\n\nBuilding inspections are one of the most important investments you'll make in this process!\n\n**What a good inspection covers:**\n- Structural integrity\n- Roof and guttering\n- Plumbing and electrical\n- Pest evidence\n- Moisture/dampness\n\n**Cost range:** $400-$800 depending on property size\n\nWould you like me to recommend some inspectors in your area?"
      ]
      responses.sample
    end

    def mock_generic_response(message)
      "[MOCKED RESPONSE]\n\n" \
        "I received your message: \"#{message.truncate(100)}\"\n\n" \
        "This is a mocked response because the Claude API is not configured. " \
        "To enable real AI responses:\n\n" \
        "1. Get an API key from https://console.anthropic.com\n" \
        "2. Set ANTHROPIC_API_KEY in your environment\n" \
        "3. Set CLAUDE_API_MOCKED=false\n\n" \
        "The Reasy AI assistants will then provide personalized guidance for your property journey!"
    end

    def estimate_tokens(text)
      # Rough estimation: ~4 characters per token
      (text.length / 4.0).ceil
    end

    # ╔═════════════════════════════════════════╗
    # ║         REAL API CALLS                   ║
    # ╚═════════════════════════════════════════╝

    def real_chat_response(messages:, system_prompt:, max_tokens:, temperature:)
      response = make_api_request(
        messages: messages,
        system: system_prompt,
        max_tokens: max_tokens,
        temperature: temperature
      )

      if response[:success]
        {
          success: true,
          mocked: false,
          response: response[:content].first[:text],
          usage: response[:usage],
          model: response[:model]
        }
      else
        {
          success: false,
          mocked: false,
          error: response[:error],
          response: nil
        }
      end
    end

    def real_stream_response(messages:, system_prompt:, max_tokens:, temperature:, &block)
      # TODO: Implement real streaming when API is configured
      # For now, fall back to non-streaming
      result = real_chat_response(
        messages: messages,
        system_prompt: system_prompt,
        max_tokens: max_tokens,
        temperature: temperature
      )

      if result[:success]
        yield({ type: "content_block_delta", delta: { text: result[:response] } })
        yield({ type: "message_stop" })
      end
    end

    def make_api_request(messages:, system:, max_tokens:, temperature:)
      uri = URI("#{@base_url}/messages")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["x-api-key"] = @api_key
      request["anthropic-version"] = "2023-06-01"

      body = {
        model: @model,
        max_tokens: max_tokens,
        temperature: temperature,
        messages: messages
      }
      body[:system] = system if system.present?

      request.body = body.to_json

      response = http.request(request)
      parsed = JSON.parse(response.body, symbolize_names: true)

      if response.code == "200"
        { success: true, **parsed }
      else
        { success: false, error: parsed[:error]&.dig(:message) || "Unknown error" }
      end
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end
end
