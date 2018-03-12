# frozen_string_literal: true

require 'English'

module Belpost
  # Chat ckass
  class Chat < BelpostBase
    has_many :links
    has_many :tracks, through: :links

    TRACK_LIMIT = 20

    after_create :init

    def init
      update_attribute(:enabled, true)
    end

    def full?
      tracks.size >= TRACK_LIMIT
    end

    def send_text(text, parse_mode = 'Markdown', kbd = nil)
      Belpost.telegram.api.send_message(
        chat_id: chat_id,
        parse_mode: parse_mode,
        disable_web_page_preview: true,
        text: text,
        reply_markup: kbd
      )
    rescue StandardError
      print_error $ERROR_INFO
    end

    def add(track, comment = '')
      raise Belpost::Error, 'Этот номер уже есть в списке' if watching? track
      raise Belpost::Error, 'Список трек-номеров переполнен' if full?

      tracks << track
      links.where(track_id: track.id, chat_id: id)
           .take
           .update_attribute(:comment, comment)
    end

    def unwatch(track)
      raise Belpost::Error, 'Такого номера нет в списке' unless watching? track

      tracks.delete track
    end

    def list_keyboard
      kbd = Telegram::Bot::Types::InlineKeyboardMarkup.new
      kbd.inline_keyboard = tracks.map { |t| list_button(t) }
      kbd
    end

    def status
      "<b>Статус</b>: #{enabled? ? 'включен' : 'выключен'}"
    end

    private

    def list_button(t)
      comment = links.where(track_id: t.id, chat_id: id).take.comment
      comment = "(#{comment.slice(0, 15)})" unless comment.empty?
      [{ text: "#{t.number} #{comment}", callback_data: "show #{t.number}" }]
    end

    def watching?(track)
      return false if track.nil?
      tracks.any? { |t| t.number == track.number }
    end

    def print_error(e)
      Belpost.log.error e.message
      update!(enabled: false) if e.message.include? 'was blocked by the user'
    end
  end
end
