class MailboxMessagesController < ApplicationController
  def create
    mailbox = Mailbox.resolve(params[:mailbox_email])
    raw = MessageBuilder.call(
      from: params.require(:from),
      to: mailbox.email,
      subject: params.require(:subject),
      body: params.require(:body)
    )
    mailbox.append_message!(raw: raw, labels: [ "INBOX" ])
    redirect_to mailbox_path(mailbox.email), notice: "Mensaje agregado al inbox."
  end

  def send_message
    mailbox = Mailbox.resolve(params[:mailbox_email])
    raw = MessageBuilder.call(
      from: mailbox.email,
      to: recipient_list(params.require(:to)),
      cc: recipient_list(params[:cc]),
      subject: params.require(:subject),
      body: params.require(:body)
    )
    message = mailbox.append_message!(raw: raw, labels: [ "SENT" ])
    LocalDelivery.call(sender_mailbox: mailbox, raw: raw, thread_id: message.thread_id)

    redirect_to mailbox_path(mailbox.email), notice: "Mensaje enviado localmente."
  end

  def reply
    mailbox = Mailbox.resolve(params[:mailbox_email])
    original = mailbox.messages.find_by!(external_id: params[:message_id])
    raw = MessageBuilder.call(
      from: mailbox.email,
      to: reply_recipients(original),
      subject: reply_subject(original),
      body: params.require(:body)
    )
    message = mailbox.append_message!(raw: raw, labels: [ "SENT" ], thread_id: original.thread_id)
    LocalDelivery.call(sender_mailbox: mailbox, raw: raw, thread_id: message.thread_id)

    redirect_to mailbox_path(mailbox.email), notice: "Respuesta enviada localmente."
  end

  private

  def recipient_list(value)
    value.to_s.split(/[,\s;]+/).map(&:strip).compact_blank
  end

  def reply_recipients(message)
    mail = message.parsed_mail
    recipients = Array(mail.from) + Array(mail.to) + Array(mail.cc)
    recipients.map { |email| email.to_s.strip.downcase }
      .reject(&:blank?)
      .reject { |email| email == message.mailbox.email }
      .uniq
  end

  def reply_subject(message)
    subject = message.parsed_mail.subject.to_s
    subject.match?(/\ARe:/i) ? subject : "Re: #{subject}"
  end
end
