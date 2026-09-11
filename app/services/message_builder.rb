require "base64"

class MessageBuilder
  def self.call(from:, to:, subject:, body:, html_body: nil, cc: nil, attachments: [])
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
    elsif attachments.present?
      mail.text_part = Mail::Part.new do
        content_type "text/plain; charset=UTF-8"
        self.body = body.to_s
      end
    else
      mail.body = body.to_s
    end

    Array(attachments).compact.each do |attachment|
      attributes = attachment_attributes(attachment)
      mail.attachments[attributes.fetch(:filename)] = {
        mime_type: attributes[:content_type].presence || "application/octet-stream",
        content: attributes.fetch(:content)
      }
    end

    mail.to_s
  end

  def self.attachment_attributes(attachment)
    if attachment.respond_to?(:original_filename)
      attachment.tempfile.rewind
      {
        filename: attachment.original_filename,
        content_type: attachment.content_type,
        content: attachment.tempfile.read
      }
    else
      values = attachment.to_h.with_indifferent_access
      {
        filename: values.fetch(:filename),
        content_type: values[:content_type],
        content: Base64.strict_decode64(values.fetch(:content_base64))
      }
    end
  end
  private_class_method :attachment_attributes
end
