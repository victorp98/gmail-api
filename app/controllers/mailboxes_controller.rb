class MailboxesController < ApplicationController
  def index
    @mailboxes = Mailbox.order(:email)
  end

  def show
    @mailbox = Mailbox.resolve(params[:email])
    @messages = @mailbox.messages.order(received_at: :desc)
  end
end
