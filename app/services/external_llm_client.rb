module ExternalLlmClient
  class TransientError < StandardError; end

  def self.classify(subject:, body:, sender:)
  
    raise TransientError, "LLM API temporary failure" if rand < 0.2

    text = "#{subject} #{body}".downcase
    important = text.include?("urgent") || text.include?("asap") || sender.to_s.downcase.include?("ceo")
    important ? :important : :general
  end
end
