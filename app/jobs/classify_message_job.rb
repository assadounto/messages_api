class ClassifyMessageJob < ApplicationJob
  queue_as :default

  MAX_ATTEMPTS = 3

  def perform(message_id)
    message = Message.find(message_id)
    return if message.classified?

    message.increment!(:classification_attempts)

    begin
      result = ExternalLlmClient.classify(
        subject: message.subject,
        body:    message.body,
        sender:  message.sender
      )

      message.update!(
        classification: result,
        status: :classified,
        classified_at: Time.current,
        last_error: nil
      )
    rescue ExternalLlmClient::TransientError => e
      if message.classification_attempts < MAX_ATTEMPTS

        message.update!(last_error: e.message)
        self.class.set(wait: backoff_for(message.classification_attempts))
                  .perform_later(message.id)
      else
        message.update!(status: :failed, last_error: e.message)
      end
    end
  end

  private

  def backoff_for(attempt)
    [ 5, 15, 30 ][attempt - 1].seconds
  end
end
