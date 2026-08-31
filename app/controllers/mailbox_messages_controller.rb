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
end
