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

  test "delivers sent messages to each recipient inbox" do
    post "#{@base}/send", params: {
      from: @email,
      to: [ "customer@example.net", "other@example.net" ],
      cc: [ "copy@example.net" ],
      subject: "Re: Help",
      body: "Response",
      thread_id: "thread-existing"
    }, as: :json

    assert_response :created
    assert_equal [ "SENT" ], response.parsed_body["labels"]

    %w[customer@example.net other@example.net copy@example.net].each do |recipient|
      mailbox = Mailbox.find_by!(email: recipient)
      message = mailbox.messages.sole
      assert_equal [ "INBOX" ], message.labels
      assert_equal "thread-existing", message.thread_id
      assert_equal @email, message.parsed_mail.from.first
    end
  end

  test "delivers raw BCC without exposing it in recipient copies" do
    raw = Mail.new do
      from @email
      to "customer@example.net"
      cc "copy@example.net"
      bcc "hidden@example.net"
      subject "Private copy"
      body "Response"
    end
    raw[:bcc].field.include_in_headers = true

    post "#{@base}/send", params: { raw: raw.to_s, thread_id: "thread-bcc" }, as: :json

    assert_response :created
    %w[customer@example.net copy@example.net hidden@example.net].each do |recipient|
      delivered = Mailbox.find_by!(email: recipient).messages.sole.parsed_mail
      assert_nil delivered.bcc
    end
  end

  test "does not deliver a duplicate inbox copy to the sender mailbox" do
    post "#{@base}/send", params: {
      from: @email,
      to: [ @email, "customer@example.net" ],
      subject: "Self copy",
      body: "Response",
      thread_id: "thread-self-copy"
    }, as: :json

    assert_response :created
    assert_equal [ "SENT" ], Mailbox.find_by!(email: @email).messages.sole.labels
    assert_equal [ "INBOX" ], Mailbox.find_by!(email: "customer@example.net").messages.sole.labels
  end

  test "web mailbox can send local email to multiple recipients" do
    post mailbox_send_message_path(@email), params: {
      to: "customer@example.net, other@example.net",
      cc: "copy@example.net",
      subject: "Browser send",
      body: "Sent from the mailbox UI"
    }

    assert_redirected_to mailbox_path(@email)
    assert_equal [ "SENT" ], Mailbox.find_by!(email: @email).messages.sole.labels
    %w[customer@example.net other@example.net copy@example.net].each do |recipient|
      assert_equal [ "INBOX" ], Mailbox.find_by!(email: recipient).messages.sole.labels
    end
  end

  test "web mailbox can reply in the same thread" do
    post mailbox_send_message_path(@email), params: {
      to: "customer@example.net",
      subject: "Browser send",
      body: "Sent from the mailbox UI"
    }

    customer_mailbox = Mailbox.find_by!(email: "customer@example.net")
    received_message = customer_mailbox.messages.sole

    post mailbox_message_reply_path(customer_mailbox.email, received_message.external_id), params: {
      body: "Customer reply"
    }

    assert_redirected_to mailbox_path(customer_mailbox.email)
    reply = customer_mailbox.messages.select { |message| message.labels == [ "SENT" ] }.sole
    agent_inbox_reply = Mailbox.find_by!(email: @email).messages.select { |message| message.labels == [ "INBOX" ] }.sole

    assert_equal received_message.thread_id, reply.thread_id
    assert_equal received_message.thread_id, agent_inbox_reply.thread_id
    assert_equal [ "customer@example.net" ], reply.parsed_mail.from
    assert_equal [ @email ], reply.parsed_mail.to
    assert_equal "Re: Browser send", reply.parsed_mail.subject
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
