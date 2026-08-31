Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "mailboxes#index"
  resources :mailboxes, only: [ :show ], param: :email, format: false, constraints: { email: /[^\/]+/ } do
    resources :messages, only: [ :create ], controller: "mailbox_messages"
  end

  namespace :api do
    namespace :v1 do
      scope format: false, constraints: { email: /[^\/]+/ } do
      get "mailboxes/:email/profile", to: "messages#profile"
      get "mailboxes/:email/messages", to: "messages#index"
      get "mailboxes/:email/messages/:id", to: "messages#show"
      post "mailboxes/:email/messages", to: "messages#create"
      post "mailboxes/:email/send", to: "messages#send_message"
      patch "mailboxes/:email/messages/:id/labels", to: "messages#update_labels"
      delete "mailboxes/:email/messages", to: "messages#destroy_all"
      end
    end
  end
end
