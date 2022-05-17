# frozen_string_literal: true

require 'db/belpost_chat'

FactoryBot.define do
  factory :chat, class: Belpost::Chat do
    chat_id { '-6574354' }
  end
end