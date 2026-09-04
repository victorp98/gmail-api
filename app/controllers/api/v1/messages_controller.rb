module Api
  module V1
    class MessagesController < ApplicationController
      include ApiAuthenticatable
      skip_forgery_protection

      before_action :set_mailbox

      def profile
        render json: { email: @mailbox.email, history_id: @mailbox.history_sequence }
      end

      def index
        scope = @mailbox.messages.order(:history_id)
        scope = scope.where("history_id > ?", params[:after_history_id].to_i) if params[:after_history_id].present?
        scope = scope.select { |message| message.labels.include?(params[:label].upcase) } if params[:label].present?
        render json: { messages: scope.first(limit).map { |message| message.as_api_json }, history_id: @mailbox.history_sequence }
      end

      def show
        render json: find_message.as_api_json(include_raw: true)
      end

      def create
        raw = MessageBuilder.call(**message_params.to_h.symbolize_keys)
        message = @mailbox.append_message!(raw: raw, labels: [ "INBOX" ], thread_id: params[:thread_id])
        render json: message.as_api_json(include_raw: true), status: :created
      end

      def send_message
        raw = params[:raw].presence || MessageBuilder.call(**message_params.to_h.symbolize_keys)
        message = @mailbox.append_message!(raw: raw, labels: [ "SENT" ], thread_id: params[:thread_id])
        LocalDelivery.call(sender_mailbox: @mailbox, raw: raw, thread_id: message.thread_id)

        render json: message.as_api_json(include_raw: true), status: :created
      end

      def update_labels
        message = find_message
        message.add_labels!(params[:add])
        message.remove_labels!(params[:remove])
        render json: message.as_api_json
      end

      def destroy_all
        @mailbox.messages.delete_all
        @mailbox.update!(history_sequence: 0)
        head :no_content
      end

      private

      def set_mailbox
        @mailbox = Mailbox.resolve(params[:email])
      end

      def find_message
        @mailbox.messages.find_by!(external_id: params[:id])
      end

      def message_params
        params.permit(:from, :subject, :body, :html_body, to: [], cc: []).tap do |permitted|
          permitted[:to] = params[:to] unless params[:to].is_a?(Array)
        end
      end

      def limit
        params.fetch(:limit, 500).to_i.clamp(1, 500)
      end
    end
  end
end
