# frozen_string_literal: true

require 'faraday'
require 'json'
require 'digest'

module Belpost
  # Track number
  class Track < BelpostBase
    has_many :links
    has_many :chats, through: :links

    validates_format_of :number, with: %r([A-Z]{2}\d{9}[A-Z]{2}), on: :create

    def watched?
      chats.any?(&:enabled?)
    end

    def refresh
      load_message
      calc_md5 if message

      return unless changed?

      chats.where(enabled: true).each do |c|
        Belpost.log.info " +++ Sending to #{c.chat_id}"
        c.send_text(chat_message(c), 'HTML')
      end
      save
      sleep 1.minute
    end

    private

    def load_message
      conn = Faraday.new 'https://api.belpost.by/api/v1/tracking', ssl: { verify: false }

      data = parse conn.post('', number: number).body
      if data.empty?
        self.message ||= ''
        return
      end

      self.message = "<b>#{number}</b>\n#{data}"
    end

    def chat_message(chat)
      result = message.split("\n")
      return '' if result.empty?

      link = links.where(chat: chat).first
      result[0] = "#{result[0]} (#{link.comment})" if link&.comment&.present?
      result.join("\n")
    end

    def calc_md5
      self.md5 = Digest::MD5.hexdigest message
    end

    def parse(data)
      hash = JSON.parse(data, symbolize_names: true)

      return {} unless hash.key?(:data)

      hash[:data].first[:steps].map do |step|
        "<b>#{step[:created_at]}</b>: #{step[:event]} <i>#{step[:place]}</i>"
      end.reverse.join("\n")
    rescue JSON::ParserError => e
      Belpost.log.error "#{number} data is invalid: #{e.message}"
      Belpost.log.error data
      ''
    end

    def cleanup(object, brackets = false)
      result = object.text.gsub(%r{^\s*}, '').gsub(%r{\s*$}, '')
      brackets && !result.empty? ? "(#{result})" : result
    end
  end
end
