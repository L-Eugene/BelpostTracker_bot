# frozen_string_literal: true

module Belpost
  # Class for Evropochta tracks
  class EvropochtaTrack < Track
    REGEX = %r{BY\d{12}}.freeze

    validates_format_of :number, with: REGEX, on: :create

    def api_get
      conn = Faraday.new 'https://evropochta.by/api/track.json/', ssl: { verify: false }

      hash = JSON.parse(conn.get('', number: number).body, symbolize_names: true)

      (hash[:data] || []).map do |step|
        "<b>#{step[:Timex]}</b>: #{step[:InfoTrack]}"
      end.reverse.join("\n")
    rescue JSON::ParserError => e
      Belpost.log.error "#{number} data is invalid: #{e.message}\n#{data}"
      ''
    end
  end
end
