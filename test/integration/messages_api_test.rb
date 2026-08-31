require "test_helper"

class MessagesApiTest < ActionDispatch::IntegrationTest
  setup do
    @email = "support@example.com"
    @base = "/api/v1/mailboxes/#{CGI.escapeURIComponent(@email)}"
  end

  test "creates and lists an inbox message" do
    post "#{@base}/messages", params: {
      from: "customer@example.net", to: @email, subject: "Help", body: "Hello"
    }, as: :json

    assert_response :created
    created = response.parsed_body
    assert_equal [ "INBOX" ], created["labels"]

    get "#{@base}/messages", params: { label: "INBOX" }
    assert_response :success
    assert_equal [ created["id"] ], response.parsed_body["messages"].map { |message| message["id"] }
  end

  test "captures sent messages in an existing thread" do
    post "#{@base}/send", params: {
      from: @email, to: "customer@example.net", subject: "Re: Help", body: "Response", thread_id: "thread-existing"
    }, as: :json

    assert_response :created
    assert_equal "thread-existing", response.parsed_body["thread_id"]
    assert_equal [ "SENT" ], response.parsed_body["labels"]
  end

  test "updates labels and exposes incremental history" do
    post "#{@base}/messages", params: {
      from: "spam@example.net", to: @email, subject: "Offer", body: "Body"
    }, as: :json
    message = response.parsed_body

    patch "#{@base}/messages/#{message["id"]}/labels", params: {
      add: [ "SPAM" ], remove: [ "INBOX" ]
    }, as: :json
    assert_response :success
    assert_equal [ "SPAM" ], response.parsed_body["labels"]

    get "#{@base}/messages", params: { after_history_id: 0 }
    assert_response :success
    assert_equal message["id"], response.parsed_body["messages"].first["id"]
  end

  test "requires bearer token when api key is configured" do
    previous = ENV["GMAIL_API_KEY"]
    ENV["GMAIL_API_KEY"] = "test-secret"

    get "#{@base}/profile"
    assert_response :unauthorized

    get "#{@base}/profile", headers: { "Authorization" => "Bearer test-secret" }
    assert_response :success
  ensure
    ENV["GMAIL_API_KEY"] = previous
  end
end
