# frozen_string_literal: true

require 'faraday'
require 'json'
require 'digest'

module Belpost
  # Track number
  class Track < BelpostBase
    has_many :links
    has_many :chats, through: :links

    validate do |track|
      next unless track.type.nil? ||
                  !track.type.constantize.const_defined?(:REGEX) ||
                  !track.type.constantize::REGEX.match?(track.number)

      errors.add(:number, 'does not match any supported type')
    end

    def watched?
      chats.any?(&:enabled?)
    end

    def self.find_or_create_by_number(number)
      result = find_by_number(number)
      return result if result

      klass = Belpost::Track.descendants.detect { |k| k::REGEX === number } || Belpost::Track
      klass.create(number: number)
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

    def api_get
      raise 'Should be defined in subclass'
    end

    def load_message
      data = api_get

      return self.message ||= '' if data.empty?

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

    def cleanup(object, brackets = false)
      result = object.text.gsub(%r{^\s*}, '').gsub(%r{\s*$}, '')
      brackets && !result.empty? ? "(#{result})" : result
    end
  end
end

require 'db/belpost_evropochta_track'
require 'db/belpost_post_track'
