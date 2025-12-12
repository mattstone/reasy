# frozen_string_literal: true

require "test_helper"

module AI
  class ClaudeClientTest < ActiveSupport::TestCase
    setup do
      @client = ClaudeClient.new
    end

    test "mocked? returns true by default" do
      # By default in test environment, API key is not set
      assert ClaudeClient.mocked?
    end

    test "status_message indicates mocked status" do
      assert_match(/MOCKED/, ClaudeClient.status_message)
    end

    test "chat returns mocked response when mocked" do
      response = @client.chat(
        messages: [{ role: "user", content: "Hello" }]
      )

      assert response[:success]
      assert response[:mocked]
      assert_not_nil response[:response]
      assert_match(/MOCKED/, response[:response])
    end

    test "chat includes mocked warning" do
      response = @client.chat(
        messages: [{ role: "user", content: "Hello" }]
      )

      assert_not_nil response[:mocked_warning]
      assert_match(/MOCKED/, response[:mocked_warning])
    end

    test "chat returns usage stats" do
      response = @client.chat(
        messages: [{ role: "user", content: "Hello" }]
      )

      assert response[:usage].present?
      assert response[:usage][:input_tokens].present?
      assert response[:usage][:output_tokens].present?
    end

    test "chat returns model info with MOCKED suffix" do
      response = @client.chat(
        messages: [{ role: "user", content: "Hello" }]
      )

      assert_match(/MOCKED/, response[:model])
    end

    test "stream_chat yields chunks" do
      chunks = []

      @client.stream_chat(
        messages: [{ role: "user", content: "Hello" }]
      ) do |chunk|
        chunks << chunk
      end

      assert chunks.any? { |c| c[:type] == "content_block_delta" }
      assert chunks.any? { |c| c[:type] == "message_stop" }
    end

    test "mocked response varies by assistant type" do
      # Max response
      max_response = @client.chat(
        messages: [{ role: "user", content: "Tell me about property" }],
        system_prompt: "You are Max, the Property Expert"
      )
      assert_match(/Max.*Property Expert/i, max_response[:response])

      # Sage response
      sage_response = @client.chat(
        messages: [{ role: "user", content: "What's the journey?" }],
        system_prompt: "You are Sage, the Journey Guide"
      )
      assert_match(/Sage.*Journey Guide/i, sage_response[:response])
    end

    test "mocked response for Nina negotiation advisor" do
      response = @client.chat(
        messages: [{ role: "user", content: "How should I negotiate?" }],
        system_prompt: "You are Nina, the Negotiation Advisor"
      )

      assert_match(/Nina.*Negotiation/i, response[:response])
    end

    test "mocked response for Doc document decoder" do
      response = @client.chat(
        messages: [{ role: "user", content: "Explain this contract" }],
        system_prompt: "You are Doc, the Document Decoder"
      )

      assert_match(/Doc.*Document/i, response[:response])
    end

    test "mocked response for Scout market researcher" do
      response = @client.chat(
        messages: [{ role: "user", content: "What's the market like?" }],
        system_prompt: "You are Scout, the Market Researcher"
      )

      assert_match(/Scout.*Market/i, response[:response])
    end

    test "mocked response for Ally service provider assistant" do
      response = @client.chat(
        messages: [{ role: "user", content: "Find me a conveyancer" }],
        system_prompt: "You are Ally, the Service Provider Assistant"
      )

      assert_match(/Ally.*Service Provider/i, response[:response])
    end

    test "generic response when no assistant detected" do
      response = @client.chat(
        messages: [{ role: "user", content: "Hello" }]
      )

      assert_match(/MOCKED RESPONSE/, response[:response])
      assert_match(/ANTHROPIC_API_KEY/, response[:response])
    end
  end
end
