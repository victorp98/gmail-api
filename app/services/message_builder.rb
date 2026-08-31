class MessageBuilder
  def self.call(from:, to:, subject:, body:, html_body: nil, cc: nil)
    mail = Mail.new
    mail.from = from
    mail.to = Array(to)
    mail.cc = Array(cc).presence
    mail.subject = subject
    mail.message_id = "#{SecureRandom.uuid}@gmail-api.local"

    if html_body.present?
      mail.text_part = Mail::Part.new { self.body = body.to_s }
      mail.html_part = Mail::Part.new do
        content_type "text/html; charset=UTF-8"
        self.body = html_body.to_s
      end
    else
      mail.body = body.to_s
    end

    mail.to_s
  end
end
