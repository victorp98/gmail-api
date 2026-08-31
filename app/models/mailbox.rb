class Mailbox < ApplicationRecord
  has_many :messages, dependent: :destroy

  normalizes :email, with: ->(value) { value.to_s.strip.downcase }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def self.resolve(email)
    find_or_create_by!(email: email)
  end

  def append_message!(raw:, labels:, thread_id: nil)
    with_lock do
      next_sequence = history_sequence + 1
      update!(history_sequence: next_sequence)
      messages.create!(
        external_id: "message-#{next_sequence}",
        thread_id: thread_id.presence || "thread-#{next_sequence}",
        history_id: next_sequence,
        raw: raw,
        labels: Array(labels).map(&:upcase).uniq,
        received_at: Time.current
      )
    end
  end
end
