# frozen_string_literal: true

require 'nokogiri'
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
    end

    private

    def load_message
      url = "https://webservices.belpost.by/searchRu/#{number}"

      data = parse Faraday.get(url).body
      return if data.empty?

      self.message = "<b>#{number}</b>\n#{data}"
    end

    def chat_message(chat)
      result = message.split("\n")
      return '' if result.empty?

      link = links.where(chat: chat).first
      result[0] = "#{result[0]} (#{link.comment})" if link.try(:comment)
      result.join("\n")
    end

    def calc_md5
      self.md5 = Digest::MD5.hexdigest message
    end

    def parse(html)
      Nokogiri::HTML(html).css('#Panel2 table tr').map do |tr|
        next if (date = tr.css('td[1]').text).empty?
        status = cleanup tr.css('td[2]')
        place = cleanup tr.css('td[3]'), true
        date.gsub!(%r{(\d{2})\.(\d{2})\.(\d{4})}, '\3-\2-\1')
        "<b>#{date}</b>: #{status} <i>#{place}</i>"
      end.compact.sort.join "\n"
    end

    def cleanup(object, brackets = false)
      result = object.text.gsub(%r{^\s*}, '').gsub(%r{\s*$}, '')
      brackets && !result.empty? ? "(#{result})" : result
    end
  end
end
