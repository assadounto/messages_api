require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "valid factory" do
    m = Message.new(subject: "Hi", body: "Body", sender: "me@example.com")
    assert_predicate m, :valid?
  end
end
