class Message < ApplicationRecord
  belongs_to :mailbox

  validates :external_id, :thread_id, :history_id, :raw, :received_at, presence: true

  def parsed_mail
    @parsed_mail ||= Mail.read_from_string(raw)
  end

  def add_labels!(values)
    update!(labels: (labels + Array(values).map(&:upcase)).uniq)
  end

  def remove_labels!(values)
    update!(labels: labels - Array(values).map(&:upcase))
  end

  def as_api_json(include_raw: false)
    data = {
      id: external_id,
      thread_id: thread_id,
      history_id: history_id,
      internal_date: (received_at.to_f * 1000).to_i,
      labels: labels,
      snippet: parsed_mail.body.decoded.to_s.first(200),
      headers: parsed_mail.header.fields.map { |field| { name: field.name, value: field.value } }
    }
    data[:raw] = raw if include_raw
    data
  end
end
