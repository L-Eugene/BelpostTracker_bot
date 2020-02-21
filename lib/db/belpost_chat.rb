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

    def show_track(message, track)
      Belpost.telegram.api.edit_message_text(
        chat_id: chat_id,
        message_id: message,
        parse_mode: 'HTML',
        disable_web_page_preview: true,
        text: track_brief(track),
        reply_markup: track_keyboard(track)
      )
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

    def delete_message(message)
      Belpost.telegram.api.delete_message(
        chat_id: chat_id,
        message_id: message
      )
    rescue Telegram::Bot::Exceptions::Base
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

    def list_button(track)
      comment = links.where(track_id: track.id, chat_id: id).take.comment
      comment = "(#{comment.slice(0, 15)})" unless comment.empty?
      [
        {
          text: "#{track.number} #{comment}",
          callback_data: "show #{track.number}"
        }
      ]
    end

    def track_keyboard(tnum)
      kbd = Telegram::Bot::Types::InlineKeyboardMarkup.new
      kbd.inline_keyboard = [
        [{ text: 'Удалить', callback_data: "delete #{tnum}" }],
        [{ text: 'Назад', callback_data: 'list' }]
      ]
      kbd
    end

    def track_brief(tnum)
      track = Belpost::Track.find_by(number: tnum)
      comment = links.where(track_id: track.id, chat_id: id).take.comment
      comment = "\n(#{comment})" unless comment.empty?
      last_three = track.message&.split("\n")&.drop(1)&.last(3)&.join("\n")
      "<b>#{tnum}</b>#{comment}\n\n#{last_three}"
    end

    def watching?(track)
      return false if track.nil?

      tracks.any? { |t| t.number == track.number }
    end

    def print_error(err)
      Belpost.log.error err.message
      update!(enabled: false) if err.message.include? 'was blocked by the user'
    end
  end
end
