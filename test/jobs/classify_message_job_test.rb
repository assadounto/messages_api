require "test_helper"

class ClassifyMessageJobTest < ActiveJob::TestCase
  test "enqueues and classifies" do
    message = Message.create!(subject: "URGENT", body: "ASAP pls", sender: "ceo@x.com")
    assert_enqueued_with(job: ClassifyMessageJob, args: [ message.id ]) do
      ClassifyMessageJob.perform_later(message.id)
    end
  end
end
