# frozen_string_literal: true 

module Belpost

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

    def send_text(text, parse_mode = 'Markdown')
      telegram.api.send_message(
        chat_id: chat_id,
        parse_mode: parse_mode,
        disable_web_page_preview: true,
        text: text
      )
    rescue StandardError
      print_error $ERROR_INFO
    end

    def add(track)
      raise Belpost::Error, 'Already tracking this number' if watching? track
      raise Belpost::Error, 'Tracknumber limit reached' if full?

      tracks << track
    end

    def unwatch(track)
      raise Belpost::Error, 'This number is not watched' unless watching? track

      tracks.delete track
    end

    def list
      <<~TEXT
        <b>enabled:</b> #{enabled? ? 'yes' : 'no'}
        #{tracks.pluck(:number).join("\n")}
      TEXT
    end

    private

    def watching?(track)
      return false if track.nil?
      tracks.any? { |t| t.number == track.number }
    end

    def telegram
      Belpost::Tlg.instance
    end

    def print_error(e)
      #
    end
  end
end
