# frozen_string_literal: true

require "test_helper"

module AI
  class AssistantServiceTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
    end

    test "initializes with valid assistant type" do
      service = AssistantService.new(user: @user, assistant_type: :max)
      assert_equal :max, service.assistant_type
    end

    test "raises error for invalid assistant type" do
      assert_raises ArgumentError do
        AssistantService.new(user: @user, assistant_type: :invalid)
      end
    end

    test "assistant_info returns correct data" do
      service = AssistantService.new(user: @user, assistant_type: :max)
      info = service.assistant_info

      assert_equal "Max", info[:name]
      assert_equal "Property Expert", info[:title]
    end

    test "all assistants have info" do
      AssistantService::ASSISTANTS.each do |type, info|
        assert info[:name].present?, "#{type} should have name"
        assert info[:title].present?, "#{type} should have title"
        assert info[:description].present?, "#{type} should have description"
        assert info[:expertise].present?, "#{type} should have expertise"
      end
    end

    test "mocked? delegates to ClaudeClient" do
      service = AssistantService.new(user: @user, assistant_type: :max)
      assert_equal ClaudeClient.mocked?, service.mocked?
    end

    test "start_conversation creates new ai_conversation" do
      service = AssistantService.new(user: @user, assistant_type: :max)

      assert_difference "AIConversation.count", 1 do
        conversation = service.start_conversation
        assert conversation.persisted?
        assert_equal "max", conversation.assistant
      end
    end

    test "chat creates messages and returns response" do
      service = AssistantService.new(user: @user, assistant_type: :max)

      result = service.chat("What should I look for in a property?")

      assert result[:message].present?
      assert result[:message].assistant?
      assert_not_nil result[:mocked]
    end

    test "chat records user message" do
      service = AssistantService.new(user: @user, assistant_type: :max)
      service.start_conversation

      service.chat("Test message")

      user_messages = service.conversation.ai_messages.where(role: "user")
      assert_equal 1, user_messages.count
      assert_equal "Test message", user_messages.first.content
    end

    test "chat records assistant message" do
      service = AssistantService.new(user: @user, assistant_type: :max)
      service.start_conversation

      result = service.chat("Test message")

      assistant_messages = service.conversation.ai_messages.where(role: "assistant")
      assert_equal 1, assistant_messages.count
      assert_equal result[:message].content, assistant_messages.first.content
    end

    test "suggested_questions returns questions for max" do
      service = AssistantService.new(user: @user, assistant_type: :max)
      questions = service.suggested_questions

      assert questions.is_a?(Array)
      assert questions.any?
      assert questions.all? { |q| q.is_a?(String) }
    end

    test "suggested_questions vary by assistant" do
      max_questions = AssistantService.new(user: @user, assistant_type: :max).suggested_questions
      sage_questions = AssistantService.new(user: @user, assistant_type: :sage).suggested_questions

      assert_not_equal max_questions, sage_questions
    end

    test "chat with property context" do
      property = create(:property, :active, :with_full_details)
      service = AssistantService.new(user: @user, assistant_type: :max)

      result = service.chat("Tell me about this property", context: { property: property })

      assert result[:message].present?
    end

    test "stream_chat yields chunks" do
      service = AssistantService.new(user: @user, assistant_type: :max)
      service.start_conversation

      chunks = []
      service.stream_chat("Hello") do |chunk|
        chunks << chunk
      end

      assert chunks.any? { |c| c[:type] == "delta" }
      assert chunks.any? { |c| c[:type] == "done" }
    end

    test "conversation persists across multiple chats" do
      service = AssistantService.new(user: @user, assistant_type: :max)

      service.chat("First message")
      service.chat("Second message")
      service.chat("Third message")

      # 3 user messages + 3 assistant messages + 1 system message
      assert_equal 7, service.conversation.ai_messages.count
    end

    test "chat updates total_tokens" do
      service = AssistantService.new(user: @user, assistant_type: :max)
      service.start_conversation

      initial_tokens = service.conversation.total_tokens

      service.chat("Test message")

      assert service.conversation.reload.total_tokens > initial_tokens
    end
  end
end
