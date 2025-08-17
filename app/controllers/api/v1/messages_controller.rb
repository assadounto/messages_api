
module Api
  module V1
    class MessagesController < ApplicationController
      # POST /api/v1/messages
      def create
        message = Message.create!(message_params)
        ClassifyMessageJob.perform_later(message.id)
        render json: serialize(message), status: :accepted
      end

      # GET /api/v1/messages
      def index
        messages = Message.order(created_at: :desc)
        render json: messages.map { |m| serialize(m) }
      end

      private

      def message_params
        params.require(:message).permit(:subject, :body, :sender)
      end

      def serialize(m)
        {
          id: m.id,
          subject: m.subject,
          sender: m.sender,
          body: m.body,
          status: m.status,
          classification: m.classification,
          attempts: m.classification_attempts,
          last_error: m.last_error,
          classified_at: m.classified_at,
          created_at: m.created_at
        }
      end
    end
  end
end
