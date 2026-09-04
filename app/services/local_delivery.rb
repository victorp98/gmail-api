class LocalDelivery
  def self.call(sender_mailbox:, raw:, thread_id:)
    new(sender_mailbox:, raw:, thread_id:).call
  end

  def initialize(sender_mailbox:, raw:, thread_id:)
    @sender_mailbox = sender_mailbox
    @raw = raw
    @thread_id = thread_id
  end

  def call
    recipient_emails.each do |email|
      Mailbox.resolve(email).append_message!(raw: recipient_raw, labels: [ "INBOX" ], thread_id: @thread_id)
    end
  end

  private

  def recipient_emails
    mail = Mail.read_from_string(@raw)
    (Array(mail.to) + Array(mail.cc) + Array(mail.bcc))
      .map { |email| email.to_s.strip.downcase }
      .reject(&:blank?)
      .reject { |email| email == @sender_mailbox.email }
      .uniq
  end

  def recipient_raw
    @recipient_raw ||= begin
      mail = Mail.read_from_string(@raw)
      mail[:bcc] = nil
      mail.to_s
    end
  end
end
