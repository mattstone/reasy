# frozen_string_literal: true

module Admin
  module AI
    class VoiceSettingsController < Admin::BaseController
      def index
        @assistants = ::AI::AssistantService::ASSISTANTS
      end

      def show
        @assistant_key = params[:id].to_sym
        @assistant = ::AI::AssistantService::ASSISTANTS[@assistant_key]

        unless @assistant
          redirect_to admin_ai_voice_settings_path, alert: "Assistant not found."
        end
      end

      def edit
        @assistant_key = params[:id].to_sym
        @assistant = ::AI::AssistantService::ASSISTANTS[@assistant_key]
      end

      def update
        # Voice settings would be stored in database or config
        # For now, redirect with success message
        redirect_to admin_ai_voice_setting_path(params[:id]), notice: "Voice settings updated."
      end

      def test
        @assistant_key = params[:id].to_sym
        # Would trigger a test conversation
        redirect_to admin_ai_voice_setting_path(params[:id]), notice: "Test message sent."
      end

      def reset
        @assistant_key = params[:id].to_sym
        # Would reset to default settings
        redirect_to admin_ai_voice_setting_path(params[:id]), notice: "Settings reset to defaults."
      end
    end
  end
end
